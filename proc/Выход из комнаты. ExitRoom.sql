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