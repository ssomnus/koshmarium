DROP PROCEDURE IF EXISTS Registration;
CREATE PROCEDURE Registration (lg VARCHAR(30), pw VARCHAR(255))
COMMENT "Регистрация (логин, пароль)"
Registration: BEGIN
    /*Проверка на правильность ввода логина*/
    IF lg IS NULL OR LENGTH(lg) < 3 
    THEN
        SELECT "Логин должен быть длиннее 3 символов" AS Error;
        LEAVE Registration;
    END IF;

    /*Проверка на правильность ввода пароля*/
    IF pw IS NULL OR LENGTH(pw) < 5 
    THEN
        SELECT "Пароль должен быть длиннее 5 символов" AS Error;
        LEAVE Registration;
    END IF;

START TRANSACTION;

    /*Добавляем вводимые данные в таблицу Users*/
    INSERT IGNORE INTO Users(Login, Password) VALUES(lg, pw);

    /*Проверка на возможность регистрации логина и пароля*/
    IF ROW_COUNT() = 0 
    THEN
        SELECT "Этот логин уже занят" AS Error;
        LEAVE Registration;
    END IF;

    /*Вход в игру*/
    CALL SignIn(lg, pw);

COMMIT;

END;