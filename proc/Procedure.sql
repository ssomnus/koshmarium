/*Регистрация*/
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
END;



/*Вход*/
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

    /*Удаление токенов, время неактивности которых > 30 минут*/
    DELETE FROM Tokens WHERE TIMESTAMPDIFF (MINUTE, date, NOW()) > 30;

    /*Добавление данных в таблицу Tokens*/
    INSERT IGNORE INTO Tokens(token, login, date) VALUES(RAND()*256*256*256*256, lg, NOW());

    /*Вывести токен текущего игрока*/
    SELECT token AS player_token FROM Tokens
        WHERE login = lg
        ORDER BY date DESC 
        LIMIT 1;

    /*Информация о комнатах*/
    CALL AllRooms();

    /*Вывести пользователей в онлайне*/
    SELECT login AS online_users FROM Tokens
        WHERE TIMESTAMPDIFF (MINUTE, date, NOW()) < 5;
END;



/*Создание комнаты*/
DROP PROCEDURE IF EXISTS CreateRoom;
CREATE PROCEDURE CreateRoom (Seats INT, TimeStep INT)
COMMENT "Создание комнаты (количество мест, время на ход)"
CreateRoom: BEGIN
	/*Переменная для автоматически созданного ID комнаты*/
	DECLARE RoomID INT;

	/*Проверка правильности вводимости мест (от 2 до 5)*/
	IF Seats IS NULL OR Seats NOT BETWEEN 2 AND 5
	THEN
		SELECT "Недопустимое количество мест. В комнате может быть от 2 до 5 игроков" AS Error;
		LEAVE CreateRoom;
	END IF;

	/*Проверка на правильность вводимости времени*/
	IF TimeStep IS NULL OR TimeStep < 60
	THEN
		SELECT "Недопустимое количество времени на ход. Значение должно составлять 60 секунд и больше" AS Error;
		LEAVE CreateRoom;
	END IF;

	/*Добавить вводимые данные в таблицу Rooms*/
	INSERT IGNORE INTO Rooms(ID, MaxSeats, TimeToStep) VALUES(NULL, Seats, TimeStep);

	/*Переносим ID комнаты во временную переменную*/
	SET RoomID = LAST_INSERT_ID();

	/*Добавить колоду на комнату*/
	INSERT INTO CardsInGame(ID, ID_Card) SELECT NULL, ID FROM Cards
		ORDER BY RAND();

	INSERT INTO CommonDeck(ID_CardInGame, ID_Room) SELECT ID, RoomID FROM CardsInGame
        ORDER BY RAND();

	/*Вывести инфу о созданной комнате*/
	SELECT * FROM Rooms
		WHERE ID = RoomID;
END;



/*Вход в комнату*/



/*Выход из комнаты*/
DROP PROCEDURE IF EXISTS ExitRoom;
CREATE PROCEDURE ExitRoom(tkn INT, RoomID INT)
COMMENT "Выйти из комнаты (токен, ID комнаты)"
ExitRoom: BEGIN
    /*Переменная для узнавания места*/
    DECLARE Seat INT DEFAULT(SELECT SeatNumber FROM Players
                                JOIN Tokens ON Players.Login = Tokens.login
                                WHERE ID_Room = RoomID AND token = tkn
                                ORDER BY date DESC 
                                LIMIT 1;)

    /*Проверка правильности ввода токена*/
    IF NOT EXISTS (SELECT * FROM Tokens 
                    WHERE token = tkn)
    THEN
        SELECT "Такого токена не существует" AS Error;
        LEAVE ExitRoom;
    END IF;

    /*Проверка правильности ввода ID комнаты*/
    IF NOT EXISTS (SELECT * FROM Rooms 
                    WHERE ID = RoomID)
    THEN
        SELECT "Такого ID комнаты не существует" AS Error;
        LEAVE ExitRoom;
    END IF;

    /*Есть ли игрок в этой комнате*/
    IF NOT EXISTS (SELECT * FROM Players
                    JOIN Tokens ON Players.Login = Tokens.login
                    WHERE ID_Room = RoomID AND token = tkn)
    THEN
        SELECT "Вас нет в этой комнате" AS Error;
        LEAVE ExitRoom;
    END IF;

    /*Удалить игрока из таблицы Players*/
    DELETE Players FROM Players
        JOIN Tokens ON Players.Login = Tokens.login
        WHERE token = tkn AND ID_Room = RoomID;

    /*Сдвинуть игроков по местам*/
    UPDATE Players SET SeatNumber = Seat - 1
        WHERE SeatNumber > Seat AND ID_Room = RoomID;

    /*Если в комнате не осталось игроков*/
    IF EXISTS (SELECT COUNT(ID) AS cnt FROM Players
                GROUP BY ID_Room
                HAVING ID_Room = RoomID AND cnt = 0)
    THEN
        DELETE FROM Rooms 
            WHERE ID = RoomID;
    END IF;
END;



/*Взять карту*/
