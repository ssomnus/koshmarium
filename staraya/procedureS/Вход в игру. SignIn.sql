DROP PROCEDURE IF EXISTS SignIn;
CREATE PROCEDURE SignIn (lg VARCHAR(30), pw VARCHAR(255))
COMMENT "Вход в систему (логин, пароль)"
SignIn: BEGIN
    /*Проверка на правильность ввода логина*/
    IF NOT EXISTS (SELECT * FROM Users
                    WHERE Login = lg)
    THEN
        SELECT "Неверный логин" AS Error;
        LEAVE SignIn;
    END IF;

    /*Проверка на правильность ввода пароля*/
    IF EXISTS (SELECT * FROM Users
                WHERE Login = lg AND Password != pw)
    THEN
        SELECT "Неверный пароль" AS Error;
        LEAVE SignIn;
    END IF;

START TRANSACTION;

    /*Удаление токенов, время неактивности которых > 30 минут*/
    DELETE FROM Tokens WHERE TIMESTAMPDIFF (MINUTE, date, NOW()) > 30;

    /*Добавление данных в таблицу Tokens*/
    INSERT IGNORE INTO Tokens(token, login, date) VALUES(RAND()*256*256*256*256, lg, NOW());

COMMIT;

    /*Вывести токен текущего игрока*/
    SELECT token AS player_token FROM Tokens
        WHERE login = lg
        ORDER BY date DESC 
        LIMIT 1;

    /*Информация о комнатах*/
    CALL AllRooms();

    /*Вывести пользователей в онлайне*/
    SELECT login AS online_users FROM Tokens
        WHERE TIMESTAMPDIFF (MINUTE, date, NOW()) < 60
        GROUP BY online_users;
END;