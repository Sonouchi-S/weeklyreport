/*ユーザの新規登録・更新
新規登録：in_new_create_fg = 1
ユーザ情報更新：in_new_create_fg = 0
戻り値out_result: 登録結果のメッセージ
*/
DELIMITER //
CREATE OR REPLACE PROCEDURE PR_USER_CREATE(
    IN in_user_id VARCHAR(20)
    ,IN in_user_ln VARCHAR(50)
    ,IN in_user_fn VARCHAR(50)
    ,IN in_user_mn VARCHAR(50)
    ,IN in_leader_fg TINYINT(1)
    ,IN in_enabled_fg TINYINT(1)
    ,IN in_department_cd CHAR(5)
    ,IN in_add_user VARCHAR(20)
    ,IN in_password VARCHAR(255)
    ,IN in_new_create_fg BOOLEAN -- 1:新規登録, 0:ユーザ情報更新
    ,OUT out_result TEXT
)
BEGIN
    -- エラーハンドル用共通
    DECLARE v_proc_name VARCHAR(30) DEFAULT 'PR_USER_CREATE'; -- プロシージャ名
    DECLARE v_sqlstate CHAR(5) DEFAULT '00000';
    DECLARE v_message TEXT;
    DECLARE v_err_param TEXT;
    -- エラーハンドルここまで

    -- プロシージャ固有
    DECLARE v_user_exists INT DEFAULT 0;
    DECLARE v_pass_exists INT DEFAULT 0;
    DECLARE v_user_mn VARCHAR(50);
    DECLARE v_leader_fg TINYINT(1);
    DECLARE v_enabled_fg TINYINT(1);
    DECLARE v_password VARCHAR(255);
    -- プロシージャ固有ここまで

    -- エラーハンドル用共通処理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            v_sqlstate = RETURNED_SQLSTATE, 
            v_message = MESSAGE_TEXT;

            -- 引数（NULL対応: IFNULLでNULLを文字列に変換）
            SET v_err_param = CONCAT(
                                    'in_user_id:'
                                    , IFNULL(in_user_id, 'NULL')
                                    , ', in_user_ln:'
                                    , IFNULL(in_user_ln, 'NULL')
                                    , ', in_user_fn:'
                                    , IFNULL(in_user_fn, 'NULL')
                                    , ', in_user_mn:'
                                    , IFNULL(in_user_mn, 'NULL')
                                    , ', in_leader_fg:'
                                    , IFNULL(in_leader_fg, 'NULL')
                                    , ', in_enabled_fg:'
                                    , IFNULL(in_enabled_fg, 'NULL')
                                    , ', in_department_cd:'
                                    , IFNULL(in_department_cd, 'NULL')
                                    , ', in_add_user:'
                                    , IFNULL(in_add_user, 'NULL')
                                    , ', in_password:'
                                    , IFNULL(in_password, 'NULL')
                                    , ', in_new_create_fg:'
                                    , IFNULL(in_new_create_fg, 'NULL')
                                    , ', v_user_exists:'
                                    , IFNULL(v_user_exists, 'NULL')
                                    , ', v_pass_exists:'
                                    , IFNULL(v_pass_exists, 'NULL')
                                    , ', v_user_mn:'
                                    , IFNULL(v_user_mn, 'NULL')
                                    , ', v_leader_fg:'
                                    , IFNULL(v_leader_fg, 'NULL')
                                    , ', v_enabled_fg:'
                                    , IFNULL(v_enabled_fg, 'NULL')
                                    );

            -- ログテーブル登録
            INSERT INTO ERR_LOG
            (
            PROC_NAME
            ,ERR_CODE
            ,ERR_MESSAGE
            ,ERR_PARAM
            )
            VALUES
            (
            v_proc_name
            ,v_sqlstate
            ,v_message
            ,v_err_param
            );

        SET out_result = CONCAT('処理の実行に失敗しました。\n管理者に問い合わせてください。\n処理\：', v_proc_name, '\nエラーコード\:', v_sqlstate, '\nエラーメッセージ\:', v_message);
    END;
    -- エラーハンドルここまで

    -- 本処理
    SET out_result = '処理の実行に失敗しました';
    IF in_user_mn IS NULL THEN
        SET v_user_mn = '';
    ELSE
        SET v_user_mn = in_user_mn;
    END IF;

    IF in_leader_fg IN (0, 1) THEN
        SET v_leader_fg = in_leader_fg;
    ELSE
        SET v_leader_fg = 0; -- デフォルト値を0に設定
    END IF;

    IF in_enabled_fg IN (0, 1) THEN
        SET v_enabled_fg = in_enabled_fg;
    ELSE
        SET v_enabled_fg = 1; -- デフォルト値を1に設定
    END IF;

    IF IFNULL(in_password, '') = '' THEN
        SET v_password = in_user_id; -- パスワードがNULLの場合、ユーザIDをパスワードとして使用
    ELSE
        SET v_password = in_password;
    END IF;

    SELECT COUNT(*) INTO v_user_exists
    FROM `USER` U
    WHERE U.USER_ID = in_user_id;

    SELECT COUNT(*) INTO v_pass_exists
    FROM `PASSWORD` P
    WHERE P.USER_ID = in_user_id;

    IF in_new_create_fg = 1 THEN -- 登録処理
        IF v_user_exists = 0 AND v_pass_exists = 0 THEN 
            START TRANSACTION;
        
            INSERT INTO `USER`
            (
            USER_ID
            , USER_LN
            , USER_FN
            , USER_MN
            , LEADER_FG
            , ENABLED_FG
            , DEPARTMENT_CD
            , ADD_DATE
            , ADD_USER)
            VALUES
            (in_user_id
            , in_user_ln
            , in_user_fn
            , v_user_mn
            , v_leader_fg
            , v_enabled_fg
            , in_department_cd
            , CURRENT_TIMESTAMP
            , in_add_user);

            INSERT INTO `PASSWORD`
            (
            USER_ID
            , PASSWORD_HASH
            , QUESTION
            , ANSWER
            , ADD_DATE
            , ADD_USER
            )
            VALUES
            (
            in_user_id
            , FC_PASS_HASH(in_user_id, v_password)
            , '未設定'
            , FC_ANSWER_HASH(in_user_id, '未設定')
            , CURRENT_TIMESTAMP
            , in_add_user
            );

            COMMIT;
            SET out_result = 'ユーザの登録が完了しました';

        ELSEIF v_user_exists > 0 THEN
            SET out_result = 'ユーザIDは既に存在しています';

        ELSEIF v_pass_exists > 0 THEN
            SET out_result = 'このユーザIDは既にパスワードが登録されています\n管理者にパスワードのリセットを依頼してください';
        END IF;
    ELSEIF in_new_create_fg = 0 THEN -- 更新処理
        IF v_user_exists > 0 THEN 
            START TRANSACTION;

            UPDATE `USER`
            SET USER_LN = in_user_ln
            , USER_FN = in_user_fn
            , USER_MN = v_user_mn
            , LEADER_FG = v_leader_fg
            , ENABLED_FG = v_enabled_fg
            , DEPARTMENT_CD = in_department_cd
            , UPDATE_DATE = CURRENT_TIMESTAMP
            , UPDATE_USER = in_add_user
            WHERE USER_ID = in_user_id;

            COMMIT;
            SET out_result = 'ユーザの情報を更新しました';

        ELSE
            SET out_result = CONCAT('ユーザIDがただしくありません。\nユーザID:', IFNULL(in_user_id,'NULL'));
        END IF;
    END IF;
END //

-- 区切り文字を ; に戻す
DELIMITER ;