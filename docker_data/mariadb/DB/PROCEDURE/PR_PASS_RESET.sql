/*
パスワード/セキュリティ質問のリセット
戻り値out_result: 処理結果のメッセージ
in_reset_fg: パスワードリセットフラグ
in_question_update_fg: 質問更新フラグ
パスワードリセットのみ: in_reset_fg = TRUE, in_question_update_fg = FALSE
パスワード変更のみ: in_reset_fg = FALSE, in_question_update_fg = FALSE
質問更新のみ: in_reset_fg = FALSE, in_question_update_fg = TRUE
*/
DELIMITER //
CREATE OR REPLACE PROCEDURE PR_PASS_RESET(
    IN in_user_id VARCHAR(20),
    IN in_new_password VARCHAR(255),
    IN in_update_user VARCHAR(20),
    IN in_reset_fg BOOLEAN,
    IN in_question VARCHAR(255),
    IN in_answer VARCHAR(255),
    IN in_question_update_fg BOOLEAN,
    OUT out_result TEXT
)
PROCBODY:BEGIN
    -- エラーハンドル用共通
    DECLARE v_proc_name VARCHAR(30); -- プロシージャ名
    DECLARE v_sqlstate CHAR(5);
    DECLARE v_message TEXT;
    DECLARE v_err_param TEXT;
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
                                    , ', in_new_password:'
                                    , IFNULL(in_new_password, 'NULL')
                                    , ', in_update_user:'
                                    , IFNULL(in_update_user, 'NULL')
                                    , ', in_reset_fg:'
                                    , IFNULL(in_reset_fg, 'NULL')
                                    , ', in_question:'
                                    , IFNULL(in_question, 'NULL')
                                    , ', in_answer:'
                                    , IFNULL(in_answer, 'NULL')
                                    , ', in_question_update_fg:'
                                    , IFNULL(in_question_update_fg, 'NULL')
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

    -- プロシージャ固有
    SET v_proc_name = 'PR_PASS_RESET';
    SET v_sqlstate = '00000';
    SET out_result = '処理の実行に失敗しました';

    -- パスワード更新のみの場合、現在のパスワードと同じかチェック
    IF NOT in_reset_fg AND NOT in_question_update_fg AND FC_PASS_CHECK(in_user_id, in_new_password) THEN
        SET out_result = '新しいパスワードは現在のパスワードと同じです\n別のパスワードを指定してください';
        LEAVE PROCBODY;
    END IF;
    
    -- 未登録のユーザーIDの場合はエラー
    IF NOT EXISTS (SELECT 1 FROM `USER` WHERE USER_ID = in_user_id) 
    OR NOT EXISTS (SELECT 1 FROM `PASSWORD` WHERE USER_ID = in_user_id)
    OR in_user_id IS NULL THEN
        SET out_result = CONCAT('未登録のユーザIDです\nユーザID: ', IFNULL(in_user_id, 'NULL'));
        LEAVE PROCBODY;
    END IF;

    IF in_reset_fg AND NOT in_question_update_fg THEN -- パスワードリセットのみの場合は、パスワードをユーザIDと同じものにリセット
        START TRANSACTION;
        UPDATE `PASSWORD`
        SET PASSWORD_HASH = FC_PASS_HASH(in_user_id, in_user_id)
            , UPDATE_DATE = CURRENT_TIMESTAMP
            , UPDATE_USER = in_update_user
        WHERE USER_ID = in_user_id;
        COMMIT;
        SET out_result = CONCAT('パスワードのリセットが完了しました\n新しいパスワード: ', in_user_id);

    ELSEIF NOT in_reset_fg AND NOT in_question_update_fg THEN -- パスワード変更のみの場合は、指定された新しいパスワードに更新
        START TRANSACTION;
        UPDATE `PASSWORD`
        SET PASSWORD_HASH = FC_PASS_HASH(in_user_id, in_new_password)
            , UPDATE_DATE = CURRENT_TIMESTAMP
            , UPDATE_USER = in_update_user
        WHERE USER_ID = in_user_id;
        COMMIT;
        SET out_result = CONCAT('パスワードの変更が完了しました\n新しいパスワード: ', in_new_password);

    ELSEIF NOT in_reset_fg AND in_question_update_fg AND in_question IS NOT NULL AND in_answer IS NOT NULL THEN -- 質問のみ更新の場合は、質問と回答を更新
        START TRANSACTION;
        UPDATE `PASSWORD`
        SET QUESTION = in_question
            , ANSWER = FC_ANSWER_HASH(in_user_id,in_answer)
            , UPDATE_DATE = CURRENT_TIMESTAMP
            , UPDATE_USER = in_update_user
        WHERE USER_ID = in_user_id; 
        COMMIT;
        SET out_result = 'セキュリティ質問の更新が完了しました';
    ELSE
        SET out_result = '不正なパラメータの組み合わせです';
    END IF;

END //

-- 区切り文字を ; に戻す
DELIMITER ;