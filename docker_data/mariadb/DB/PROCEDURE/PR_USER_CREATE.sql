/*ユーザの新規登録
戻り値out_result: 登録結果のメッセージ
*/
DELIMITER //
CREATE OR REPLACE PROCEDURE PR_USER_CREATE(
    IN in_user_id VARCHAR(20),
    IN in_user_ln VARCHAR(50),
    IN in_user_fn VARCHAR(50),
    IN in_user_mn VARCHAR(50),
    IN in_leader_fg TINYINT(1),
    IN in_department_cd CHAR(5),
    IN in_add_user VARCHAR(20),
    IN in_password VARCHAR(255),
    OUT out_result TEXT
)
BEGIN
    DECLARE v_user_exists INT DEFAULT 0;
    DECLARE v_pass_exists INT DEFAULT 0;
    DECLARE v_user_mn VARCHAR(50);
    DECLARE v_leader_fg TINYINT(1);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET out_result = '処理の実行に失敗しました';
        RETURN;
    END;

    IF in_user_mn IS NULL THEN
        SET v_user_mn = '';
    ELSE
        SET v_user_mn = in_user_mn;
    END IF;

    IF in_leader_fg IN (0, 1) THEN
        SET v_leader_fg = in_leader_fg;
    ELSE
        SET v_leader_fg = 0; -- デフォルト値を0に設定
    END IF;

    SELECT COUNT(*) INTO v_user_exists
    FROM `USER` U
    WHERE U.USER_ID = in_user_id;

    SELECT COUNT(*) INTO v_pass_exists
    FROM `PASSWORD` P
    WHERE P.USER_ID = in_user_id;

    IF v_user_exists = 0 AND v_pass_exists = 0 THEN
        START TRANSACTION;

        INSERT INTO `USER`
        (USER_ID, USER_LN, USER_FN, USER_MN, LEADER_FG, DEPARTMENT_CD, ADD_DATE, ADD_USER)
        VALUES
        (in_user_id, in_user_ln, in_user_fn, v_user_mn, v_leader_fg, in_department_cd,
         CURRENT_TIMESTAMP, in_add_user);

        INSERT INTO `PASSWORD`
        (USER_ID, PASSWORD_HASH, QUESTION, ANSWER, ADD_DATE, ADD_USER)
        VALUES
        (in_user_id,
         FC_PASS_HASH(in_user_id, in_password),
         '未設定',
         FC_ANSWER_HASH(in_user_id, '未設定'),
         CURRENT_TIMESTAMP,
         in_add_user);

        COMMIT;
        SET out_result = 'ユーザの登録が完了しました';

    ELSEIF v_user_exists > 0 THEN
        SET out_result = 'ユーザIDは既に存在しています';

    ELSEIF v_pass_exists > 0 THEN
        SET out_result = 'このユーザIDは既にパスワードが登録されています\n管理者にパスワードのリセットを依頼してください';
    END IF;
END //

-- 区切り文字を ; に戻す
DELIMITER ;