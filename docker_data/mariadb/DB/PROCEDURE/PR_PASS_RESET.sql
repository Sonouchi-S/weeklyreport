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
BEGIN
    SET out_result = '処理の実行に失敗しました';

        -- エラーハンドラーを追加: SQLEXCEPTIONが発生したら終了し、is_valid (FALSE) を返す
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- 必要に応じてエラーログを追加
        ROLLBACK;
        SET out_result = '処理の実行に失敗しました';
        RETURN;
    END;

    -- パスワード更新のみの場合、現在のパスワードと同じかチェック
    IF NOT in_reset_fg AND NOT in_question_update_fg
    AND FC_PASS_CHECK(in_user_id, in_new_password) THEN
        SET out_result = '新しいパスワードは現在のパスワードと同じです\n別のパスワードを指定してください';
        RETURN;
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

    ELSEIF NOT in_reset_fg AND in_question_update_fg THEN -- 質問のみ更新の場合は、質問と回答を更新
        START TRANSACTION;
        UPDATE `PASSWORD`
        SET QUESTION = in_question
            , ANSWER = in_answer
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