/*
ログインチェック
戻り値out_result_check: ログインチェック結果
戻り値out_result_remark: 処理結果のメッセージ
*/
DELIMITER //
CREATE OR REPLACE PROCEDURE PR_LOGIN_CHECK(
    IN in_user_id VARCHAR(20),
    IN in_password VARCHAR(255),
    OUT out_result_check BOOLEAN,
    OUT out_result_remark TEXT
)
PROCBODY:BEGIN
    -- エラーハンドル用共通
    DECLARE v_proc_name VARCHAR(30); -- プロシージャ名
    DECLARE v_sqlstate CHAR(5);
    DECLARE v_message TEXT;
    DECLARE v_err_param TEXT;
    
    -- プロシージャ固有
    DECLARE v_enabled_fg BOOLEAN; -- ユーザー有効性フラグ
    DECLARE v_pass_check BOOLEAN; -- パスワードチェック結果
    DECLARE v_question TEXT; -- 秘密の質問

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
                                    , ', in_password:'
                                    , IFNULL(in_password, 'NULL')
                                    , ', v_enabled_fg:'
                                    , IFNULL(v_enabled_fg, 'NULL')
                                    , ', v_pass_check:'
                                    , IFNULL(v_pass_check, 'NULL')
                                    , ', v_question:'
                                    , IFNULL(v_question, 'NULL')
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
            SET out_result_remark = CONCAT('処理の実行に失敗しました。\n管理者に問い合わせてください。\n処理\：', v_proc_name, '\nエラーコード\:', v_sqlstate, '\nエラーメッセージ\:', v_message);
    END;

    -- プロシージャ名セット
    SET v_proc_name = 'PR_LOGIN_CHECK';
    SET v_sqlstate = '00000';
    SET out_result_check = FALSE; -- 初期値はFALSE
    SET out_result_remark = 'ログインに失敗しました';

    IF in_user_id IS NULL OR NOT EXISTS (SELECT 1 FROM USER WHERE USER_ID = in_user_id) THEN
        SET out_result_remark = 'ユーザーIDがただしくありません\nユーザーID:' + IFNULL(in_user_id,'入力なし');
        LEAVE PROCBODY;
    END IF;

    SET v_pass_check = FC_PASS_CHECK(in_user_id, in_password); -- パスワードチェックファンクション呼び出し
    SET v_enabled_fg = FALSE; -- 初期値はFALSE

    -- ユーザー有効性チェック
    SELECT EXISTS (
        SELECT 1 FROM USER 
        WHERE USER_ID = in_user_id AND ENABLE_FG = 1
    ) INTO v_enabled_fg;

    -- ログインチェック処理（例: ユーザーテーブルからユーザーIDとパスワードを照合）
    IF v_pass_check AND v_enabled_fg THEN
        SET out_result_check = TRUE;
        SET out_result_remark = 'ログインに成功しました';
    ELSEIF NOT v_enabled_fg THEN
        SET out_result_remark = 'ユーザーは無効です。管理者に問い合わせてください。';
    ELSEIF v_enabled_fg AND NOT v_pass_check  THEN

        -- 秘密の質問を取得
        SELECT QUESTION INTO v_question
        FROM `PASSWORD`
        WHERE USER_ID = in_user_id;

        SET out_result_remark = CONCAT('パスワードがただしくありません。\n 再度入力するか、秘密の質問に回答してパスワードをリセットしてください。\n質問：', v_question);
    END IF;
END//
DELIMITER ;