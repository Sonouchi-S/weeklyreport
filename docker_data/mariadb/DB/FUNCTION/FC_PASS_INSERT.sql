/*
パスワード登録
戻り値is_valid: 登録成功かどうか
TRUE: 登録成功
FALSE: 登録失敗
*/
DELIMITER //
CREATE OR REPLACE FUNCTION FC_PASS_INSERT(in_user_id VARCHAR(20)
                                        , in_password VARCHAR(255)
                                        , in_question VARCHAR(255)
                                        , in_answer VARCHAR(255)
                                        , in_add_user VARCHAR(20))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE is_valid BOOLEAN DEFAULT FALSE;    
        -- エラーハンドラーを追加: SQLEXCEPTIONが発生したら終了し、is_valid (FALSE) を返す
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- 必要に応じてエラーログを追加（例: INSERT INTO error_log VALUES (...)）
        RETURN is_valid;  -- FALSEを返す
    END;
    
        INSERT INTO PASSWORD 
        (USER_ID 
        ,PASSWORD_HASH
        ,QUESTION
        ,ANSWER
        ,ADD_DATE
        ,ADD_USER
        ) 
        VALUES 
        (in_user_id
        ,FC_PASS_HASH(in_user_id, in_password)
        ,in_question
        ,in_answer
        ,CURRENT_TIMESTAMP
        ,in_add_user
        );
    SET is_valid = TRUE;
    RETURN is_valid;
END //

DELIMITER ;