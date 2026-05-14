/* 部署マスタ登録/更新プロシージャ
新規登録：in_new_create_fg = TRUE
更新：in_new_create_fg = FALSE
戻り値out_result: 登録結果のメッセージ
*/
DELIMITER //
CREATE OR REPLACE PROCEDURE PR_DEPARTMENT_CREATE(
    IN in_department_cd CHAR(5)
    ,IN in_department_nm VARCHAR(20)
    ,IN in_add_user VARCHAR(20)
    ,IN in_new_create_fg BOOLEAN -- TRUE:新規登録, FALSE:部署情報更新
    ,OUT out_result TEXT
)
BEGIN
    -- エラーハンドル用共通
    DECLARE v_proc_name VARCHAR(30) DEFAULT 'PR_DEPARTMENT_CREATE'; -- プロシージャ名
    DECLARE v_sqlstate CHAR(5) DEFAULT '00000';
    DECLARE v_message TEXT;
    DECLARE v_err_param TEXT;
    -- エラーハンドルここまで

        -- エラーハンドル用共通処理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1
            v_sqlstate = RETURNED_SQLSTATE, 
            v_message = MESSAGE_TEXT;

            -- 引数（NULL対応: IFNULLでNULLを文字列に変換）
            SET v_err_param = CONCAT(
                                    'in_department_cd:'
                                    , IFNULL(in_department_cd, 'NULL')
                                    , ', in_department_nm:'
                                    , IFNULL(in_department_nm, 'NULL')
                                    , ', in_add_user:'
                                    , IFNULL(in_add_user, 'NULL')
                                    , ', in_new_create_fg:'
                                    , IFNULL(in_new_create_fg, 'NULL')
                                    );

            -- ログテーブル登録
            INSERT INTO ERR_LOG
            (
            PROC_NAME
            ,ERR_CODE
            ,ERR_MESSAGE
            ,ERR_PARAM
            )
            VALUES
            (
            v_proc_name
            ,v_sqlstate
            ,v_message
            ,v_err_param
            );

        SET out_result = CONCAT('処理の実行に失敗しました。\n管理者に問い合わせてください。\n処理\：', v_proc_name, '\nエラーコード\:', v_sqlstate, '\nエラーメッセージ\:', v_message);
    END;
    -- エラーハンドルここまで


    -- 本処理
    SET out_result = '処理の実行に失敗しました';
    IF in_department_cd IS NULL OR in_department_nm IS NULL  THEN
        SET out_result = '必須項目が未入力です。';
    ELSE
        IF in_new_create_fg THEN -- 登録処理
            IF EXISTS (SELECT 1 FROM DEPARTMENT WHERE DEPARTMENT_CD = in_department_cd) AND in_new_create_fg THEN
                SET out_result = CONCAT('この部署コードは既に登録されています。\n部署コード：', in_department_cd);
            ELSE
                INSERT INTO DEPARTMENT (
                    DEPARTMENT_CD
                    ,DEPARTMENT_NAME
                    ,ADD_DATE
                    ,ADD_USER
            ) VALUES (
                in_department_cd
                ,in_department_nm
                ,NOW()
                ,in_add_user
            );
            SET out_result = '部署の登録が完了しました。';
            END IF;
        ELSE -- 更新処理
            UPDATE DEPARTMENT 
            SET DEPARTMENT_NAME = in_department_nm
                ,UPDATE_DATE = NOW()
                ,UPDATE_USER = in_add_user
            WHERE DEPARTMENT_CD = in_department_cd;
            SET out_result = '部署の更新が完了しました。';
        END IF;
    END IF;




END //

-- 区切り文字を ; に戻す
DELIMITER ;