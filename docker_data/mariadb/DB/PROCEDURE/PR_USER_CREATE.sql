-- ユーザの新規登録
DELIMITER //
CREATE OR REPLACE PROCEDURE PR_USER_CREATE(
    IN in_user_id VARCHAR(20),
    IN in_user_ln VARCHAR(50),
    IN in_user_fn VARCHAR(50),
    IN in_user_mn VARCHAR(50),
    IN in_leader_fg TINYINT(1),
    IN in_department_cd CHAR(5),
    IN in_add_user VARCHAR(20),
    OUT out_result TEXT
)
BEGIN
    DECLARE out_result TEXT DEFAULT 'ユーザの登録に失敗しました';

    -- ユーザテーブルとパスワードテーブルのデータ存在チェック
    SELECT U.USER_ID INTO is_user
    FROM USER U
    WHERE U.USER_ID = in_user_id;

    SELECT P.USER_ID INTO is_passuser
    FROM PASSWORD P
    WHERE P.USER_ID = in_user_id;

    IF is_user IS NULL AND is_passuser IS NULL THEN -- ユーザーが存在しない場合は登録処理開始
        START TRANSACTION;
        IF FC_USER_INSERT(in_user_id
                            , in_user_ln
                            , in_user_fn
                            , in_user_mn
                            , in_leader_fg
                            , in_department_cd
                            , in_add_user)
            AND FC_PASS_INSERT(in_user_id
                            , in_user_id -- パスワードはユーザIDと同じものを初期値として登録
                            , ""         -- in_question は未使用のため空文字を登録
                            , ""         -- in_answer は未使用のため空文字を登録
                            , in_add_user) 
        THEN
            COMMIT;
            SET out_result = 'ユーザとパスワードの登録が完了しました\nユーザID: ' + in_user_id + '\nパスワード: ' + in_user_id  ;
        ELSE
            ROLLBACK;
            SET out_result = '登録に失敗しました';
        END IF;
    ELSE IF is_user IS NOT NULL THEN
        SET out_result = 'ユーザIDは既に存在しています';
    ELSE IF is_passuser IS NOT NULL THEN
        SET out_result = 'このユーザIDは既にパスワードが登録されています';
    END IF;
END //

-- 区切り文字を ; に戻す
DELIMITER ;