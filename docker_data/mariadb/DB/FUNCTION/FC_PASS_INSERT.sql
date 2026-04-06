-- パスワード登録
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
        ,NOW()
        ,in_add_user
        );
    SET is_valid = TRUE;
    RETURN is_valid;
END //

DELIMITER ;