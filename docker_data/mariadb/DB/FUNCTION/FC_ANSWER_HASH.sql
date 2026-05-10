/*
秘密の質問の回答をハッシュ化する関数
戻り値: ハッシュ化された回答
*/
DELIMITER //
CREATE OR REPLACE FUNCTION FC_ANSWER_HASH(in_user_id VARCHAR(20), in_answer VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE hashed_answer VARCHAR(255);
    
    -- in_user_idがNULLの場合、NULLを返す
    IF in_user_id IS NULL OR LTRIM(in_user_id) = '' THEN
        RETURN NULL;
    END IF;
    -- in_answerがNULLまたは空文字の場合、NULLを返す
    IF in_answer IS NULL OR LTRIM(in_answer) = '' THEN
        RETURN NULL;
    END IF;

    -- 回答をハッシュ化
    SET hashed_answer = SHA2(CONCAT(in_user_id, 'QuestionAnswer', in_answer), 256);
    
    RETURN hashed_answer;
END //
DELIMITER ;

