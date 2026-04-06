-- パスワードチェック用ファンクションの例
DELIMITER //

CREATE OR REPLACE FUNCTION FC_PASS_CHECK(in_user_id VARCHAR(20), in_password VARCHAR(255))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE is_valid BOOLEAN;
    
    -- パスワードテーブルを参照して一致するか確認
    SELECT EXISTS (
        SELECT 1 FROM PASSWORD 
        WHERE user_id = in_user_id AND password = FC_PASS_HASH(in_user_id, in_password)
    ) INTO is_valid;
    
    RETURN is_valid;
END //

DELIMITER ;