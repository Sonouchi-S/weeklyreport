/*部署削除
戻り値out_result: 処理結果のメッセージ
*/
DELIMITER //
CREATE OR REPLACE PROCEDURE PR_DEPARTMENT_DELETE(
    IN in_department_cd CHAR(5),
    OUT out_result TEXT
)
BEGIN
    -- エラーハンドル用共通
    DECLARE v_proc_name VARCHAR(30); -- プロシージャ名
    DECLARE v_sqlstate CHAR(5);
    DECLARE v_message TEXT;
    DECLARE v_err_param TEXT;
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

    -- プロシージャ名セット
    SET v_proc_name = 'PR_DEPARTMENT_DELETE';
    SET v_sqlstate = '00000';
    SET out_result = '処理の実行に失敗しました';
    IF NOT EXISTS (SELECT 1 FROM DEPARTMENT WHERE DEPARTMENT_CD = in_department_cd) THEN
    SET out_result = CONCAT('部署コードがただしくありません\n部署コード:', IFNULL(in_department_cd,'NULL'));
    ELSE
        DELETE FROM `DEPARTMENT`
               WHERE DEPARTMENT_CD = in_department_cd;
        SET out_result = '部署を削除しました';
    END IF;

END//
DELIMITER ;
