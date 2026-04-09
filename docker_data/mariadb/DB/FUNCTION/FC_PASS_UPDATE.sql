/*
パスワード更新
戻り値is_valid: 更新成功かどうか
TRUE: 更新成功
FALSE: 更新失敗
*/
DELIMITER //
CREATE OR REPLACE FUNCTION FC_PASS_UPDATE(in_user_id VARCHAR(20)
                                        , in_password VARCHAR(255)
                                        , in_update_user VARCHAR(20)
                                        , in_question VARCHAR(255) DEFAULT NULL
                                        , in_answer VARCHAR(255) DEFAULT NULL
                                        )
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE is_valid BOOLEAN DEFAULT FALSE;
    DECLARE sel_user_id VARCHAR(20);
    DECLARE sel_pass_hash VARCHAR(255);
    DECLARE sel_question VARCHAR(255);
    DECLARE sel_answer VARCHAR(255);

        -- エラーハンドラーを追加: SQLEXCEPTIONが発生したら終了し、is_valid (FALSE) を返す
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- 必要に応じてエラーログを追加（例: INSERT INTO error_log VALUES (...)）
        RETURN is_valid;  -- FALSEを返す
    END;

    SELECT USER_ID, PASSWORD_HASH, QUESTION, ANSWER
    INTO sel_user_id, sel_pass_hash, sel_question, sel_answer
    FROM PASSWORD
    WHERE USER_ID = in_user_id;

    IF in_password IS NULL THEN -- パスワードは変更せず、質問と回答のみ更新の場合
        UPDATE PASSWORD
        SET QUESTION = in_question
            , ANSWER = in_answer
            , UPDATE_DATE = CURRENT_TIMESTAMP
            , UPDATE_USER = in_update_user
        WHERE USER_ID = in_user_id;        
    ELSE
        UPDATE PASSWORD
        SET PASSWORD_HASH = FC_PASS_HASH(in_user_id, in_password)
            , UPDATE_DATE = CURRENT_TIMESTAMP
            , UPDATE_USER = in_update_user
        WHERE USER_ID = in_user_id;
    END IF;
    SET is_valid = TRUE;
    RETURN is_valid;
END //

DELIMITER ;
