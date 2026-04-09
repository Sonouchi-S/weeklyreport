/*
パスワードをハッシュ化する関数
戻り値: ハッシュ化されたパスワード
*/

DELIMITER //
CREATE OR REPLACE FUNCTION FC_PASS_HASH(in_user_id VARCHAR(20), in_password VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE hashed_password VARCHAR(255);
    
    -- パスワードをハッシュ化
    SET hashed_password = SHA2(CONCAT(in_user_id, 'user', in_password), 256);
    
    RETURN hashed_password;
END //
DELIMITER ;
