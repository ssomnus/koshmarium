DROP PROCEDURE IF EXISTS EntranceRoom;
CREATE PROCEDURE EntranceRoom (tkn INT, RoomID INT)
COMMENT "Войти в комнату (токен, ID комнаты)"
EntranceRoom: BEGIN
    /*Переменная для определения места*/
    DECLARE Seat INT DEFAULT(SELECT COUNT(Players.ID) FROM Players
                                GROUP BY ID_Room
                                HAVING ID_Room = RoomID);

    /*Переменная для определения логина*/
    DECLARE lg VARCHAR(30) DEFAULT(SELECT login FROM Tokens
                                    WHERE token = tkn);

    /*Переменная для переноса ID игрока*/
    DECLARE PlayerID INT;

    /*Переменная для определения первого ходящего*/
    DECLARE FirstPlayer INT;

    /*Проверка на правильность ввода токена*/
    IF NOT EXISTS (SELECT * FROM Tokens
                    WHERE token != tkn)
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
        IF EXISTS (SELECT COUNT(Players.ID) AS cnt FROM Players
                    JOIN Rooms ON Players.ID_Room = Rooms.ID
                    GROUP BY ID_Room
                    HAVING ID_Room = RoomID AND MaxSeats = cnt)
        THEN
            SELECT "Свободных мест больше нет" AS Error;
            LEAVE EntranceRoom;
        ELSE
            /*Еще есть свободные места*/
            IF 0 = (SELECT COUNT(ID) FROM Players
                        GROUP BY ID_Room
                        HAVING ID_Room = RoomID)
            THEN
                SET Seat = 0;
            ELSE
                SET Seat = (SELECT MAX(SeatNumber) FROM Players
                                WHERE ID_Room = RoomID) + 1;
            END IF;
                        
            /*Добавление игрока в таблицу Players*/
            INSERT INTO Players(ID, Login, ID_Room, SeatNumber) VALUES(NULL, lg, RoomID, Seat);
            SET PlayerID = LAST_INSERT_ID();

            /*Добавление 5 стартовых карт игроку в таблицу PlayerDeck*/
            INSERT INTO PlayerDeck(ID_Card, ID_Player, CardIsDiscarded) SELECT ID_CardInGame, PlayerID, "NO" FROM CommonDeck
                LIMIT 5;

            /*Удаление этих карт из таблицы CommonDeck*/
            DELETE CommonDeck FROM CommonDeck 
                JOIN PlayerDeck ON CommonDeck.ID_CardInGame = PlayerDeck.ID_Card 
                WHERE ID_CardInGame = ID_Card;

            SELECT "Не все места заняты. Пожалуйста, ожидайте других игроков" AS System;
        END IF;

    /*Игрок уже добавился в комнату*/
    ELSE
        /*Если в комнате все игроки*/
        IF EXISTS (SELECT * FROM Players
                    WHERE ID_Room = RoomID AND MaxSeats = Seat)
        THEN
            /*Если это начало игры*/
            IF EXISTS (SELECT * FROM Moves
                        JOIN Players ON Moves.ID_Player = Players.ID
                        WHERE ID_Room = RoomID)
            THEN
                /*ЗДЕСЬ МОЖНО ПЕРЕМЕШАТЬ МЕСТА*/

                /*Определение игрока, начинающего игру*/
                SET FirstPlayer = (SELECT ID FROM Players 
                                    WHERE ID_Room = RoomID AND SeatNumber = 1);

                /*Начинает ходить игрок, сидящий на 1 месте*/
                INSERT INTO Moves(ID_Player, RemainingSteps, Deadline) SELECT FirstPlayer, 2, DATE_ADD(NOW(), INTERVAL TimeToStep SECOND) FROM Rooms;
            END IF;
        /*Текущее состояние на поле*/
        CALL GameState(tkn, RoomID);
        ELSE
            SELECT "Не все места заняты. Пожалуйста, ожидайте других игроков" AS System;
        END IF;
    END IF;
END;