-- ユーザ登録
DELIMITER //
CREATE OR REPLACE FUNCTION FC_USER_INSERT(in_user_id VARCHAR(20)
                                        , in_user_ln VARCHAR(50)
                                        , in_user_fn VARCHAR(50)
                                        , in_user_mn VARCHAR(50)
                                        , in_leader_fg TINYINT(1)
                                        , in_department_cd CHAR(5)
                                        , in_add_user VARCHAR(20))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE is_valid BOOLEAN DEFAULT FALSE;    
        INSERT INTO USER 
        (USER_ID
        ,USER_LN
        ,USER_FN
        ,USER_MN
        ,LEADER_FG
        ,DEPARTMENT_CD
        ,ADD_DATE
        ,ADD_USER
        ) 
        VALUES 
        (in_user_id
        ,in_user_ln
        ,in_user_fn
        ,in_user_mn
        ,in_leader_fg
        ,in_department_cd
        ,NOW()
        ,in_add_user
        );
    SET is_valid = TRUE;
    RETURN is_valid;
END //

DELIMITER ;