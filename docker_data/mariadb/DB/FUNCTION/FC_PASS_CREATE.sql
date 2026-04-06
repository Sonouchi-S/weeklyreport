-- パスワード登録
DELIMITER //
CREATE OR REPLACE FUNCTION FC_PASS_CREATE(in_user_id VARCHAR(20)
                                        , in_password VARCHAR(255)
                                        , in_question VARCHAR(255)
                                        , in_answer VARCHAR(255)
                                        , in_add_user VARCHAR(20))
RETURNS TEXT
DETERMINISTIC
BEGIN
    DECLARE is_result TEXT DEFAULT 'パスワードの登録に失敗しました';
    DECLARE is_user VARCHAR(20);
    DECLARE is_hash VARCHAR(255);
    
    -- パスワードテーブルを参照して一致するか確認
    -- (将来的にハッシュ化する場合はここを書き換えるだけで済みます)
    SELECT USER_ID, PASSWORD_HASH INTO is_user, is_hash  FROM PASSWORD 
        WHERE user_id = in_user_id;

    IF is_user IS NOT NULL THEN -- ユーザーが存在する場合はハッシュチェック
        IF is_hash = FC_PASS_HASH(in_user_id, in_password) THEN
            RETURN 'このパスワードは既に登録済みです';
        ELSE
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
            RETURN 'パスワードの登録に成功しました';
        END IF;
    ELSE
        RETURN 'ユーザーIDが間違えているか、存在しません。';
    END IF;

    RETURN is_result;
END //

DELIMITER ;