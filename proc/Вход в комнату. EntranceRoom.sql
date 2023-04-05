DROP PROCEDURE IF EXISTS EntranceRoom;
CREATE PROCEDURE EntranceRoom (tkn INT, RoomID INT)
COMMENT "Войти в комнату (токен, ID комнаты)"
EntranceRoom: BEGIN
    /*Переменная для определения места*/
    DECLARE Seat INT DEFAULT(SELECT COUNT(ID) FROM Players
                                WHERE ID_Room = RoomID);

    /*Переменная для определения логина*/
    DECLARE lg VARCHAR(30) DEFAULT(SELECT login FROM Tokens
                                    WHERE token = tkn);

    /*Переменная для переноса ID игрока*/
    DECLARE PlayerID INT;

    /*Переменная для определения первого ходящего*/
    DECLARE FirstPlayer INT;

    /*Проверка на правильность ввода токена*/
    IF NOT EXISTS (SELECT * FROM Tokens
                    WHERE token = tkn)
    THEN
        SELECT "Такого токена не существует" AS Error;
        LEAVE EntranceRoom;
    END IF;

    /*Проверка на правильность ввода ID комнаты*/
    IF NOT EXISTS (SELECT * FROM Rooms
                    WHERE ID = RoomID)
    THEN
        SELECT "Такого ID комнаты не существует" AS Error;
        LEAVE EntranceRoom;
    END IF;

    /*Если это первый вход в комнату*/
    IF NOT EXISTS (SELECT * FROM Players
                    WHERE ID_Room = RoomID AND Login = lg)
    THEN
        /*Проверка на свободные места*/
        IF Seat = (SELECT MaxSeats FROM Rooms
                    WHERE ID = RoomID)
        THEN
            SELECT "Свободных мест больше нет" AS Error;
            LEAVE EntranceRoom;

        /*Еще есть свободные места*/
        ELSE
            SET Seat = Seat + 1;
                        
            /*Добавление игрока в таблицу Players*/
            INSERT INTO Players(ID, Login, ID_Room, SeatNumber) VALUES(NULL, lg, RoomID, Seat);
            SET PlayerID = LAST_INSERT_ID();

            /*Вывод ID игрока*/
            SELECT ID AS ID_Player FROM Players
                WHERE ID = PlayerID;

            /*Добавление 5 стартовых карт игроку в таблицу PlayerDeck*/
            INSERT INTO PlayerDeck(ID_Card, ID_Player, CardIsDiscarded) SELECT ID_CardInGame, PlayerID, "NO" FROM CommonDeck
                WHERE ID_Room = RoomID
                ORDER BY ID_CardInGame
                LIMIT 5;

            /*Удаление этих карт из таблицы CommonDeck*/
            DELETE CommonDeck FROM CommonDeck 
                JOIN PlayerDeck ON CommonDeck.ID_CardInGame = PlayerDeck.ID_Card 
                WHERE ID_CardInGame = ID_Card;

            CALL StayAtRoom(tkn, PlayerID, RoomID);
        END IF;

    /*Игрок уже добавился в комнату*/
    ELSE
        CALL StayAtRoom(tkn, PlayerID, RoomID);
    END IF;
END;