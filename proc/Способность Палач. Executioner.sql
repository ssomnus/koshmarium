DROP PROCEDURE IF EXISTS Executioner;
CREATE PROCEDURE Executioner(tkn int(10) unsigned, PlayerID INT, RoomID INT, CardID INT, MonsterID INT)
COMMENT "Способность Палач (токен, ID игрока, ID комнаты, ID карты, ID монстра)"
Executioner: BEGIN
    /*Переменная для определения ID игрока, у которого забирается карта*/
    DECLARE plID INT DEFAULT(SELECT ID_Player FROM Monsters
                            JOIN MonsterCards ON Monsters.ID = MonsterCards.ID_Monster
                            WHERE ID_CardInGame = CardID);
    
    /*Подсчет карт в монстре*/
    DECLARE countCard INT DEFAULT (SELECT COUNT(ID_CardInGame) FROM MonsterCards
                                    GROUP BY ID_Monster
                                    HAVING ID_Monster = MonsterID);

    DECLARE monst INT DEFAULT(SELECT ID_Monster FROM MonsterCards
                                JOIN Monsters ON MonsterCards.ID_Monster = Monsters.ID
                                JOIN Players ON Monsters.ID_Player = Players.ID
                                WHERE 3 = (SELECT COUNT(ID_CardInGame) FROM MonsterCards
                                            GROUP BY ID_Monster)
                                    AND ID_Room = RoomID AND AbilityIsBeingUsed = "NO");

    DECLARE card INT DEFAULT 0;

    /*Переменная для узнавания места*/
    DECLARE Seat INT DEFAULT(SELECT SeatNumber FROM Players
                                WHERE ID = PlayerID);

    /*Переменная для определения ID следующего ходящего*/
    DECLARE NowPlayer INT DEFAULT(SELECT ID FROM Players
                                        WHERE ID_Room = RoomID AND SeatNumber = 1);

    /*Определение части тела выбранной карты*/
    DECLARE partBody VARCHAR(30) DEFAULT(SELECT NameBodyPart FROM UsedParts
                                            JOIN MonsterCards ON UsedParts.ID_Card = MonsterCards.ID_CardInGame
                                            WHERE ID_CardInGame = CardID);

    /*Проверка на правильность ввода токена*/
    IF NOT EXISTS (SELECT * FROM Tokens 
                    WHERE token = tkn)
    THEN
        SELECT "Такого токена не существует" AS Error;
        LEAVE Executioner;
    END IF;

    /*Проверка на правильность ввода ID игрока*/
    IF NOT EXISTS (SELECT * FROM Players 
                    WHERE ID = PlayerID)
    THEN
        SELECT "Такого ID игрока не существует" AS Error;
        LEAVE Executioner;
    END IF;

    /*Проверка на правильность ввода ID комнаты*/
    IF NOT EXISTS (SELECT * FROM Rooms 
                    WHERE ID = RoomID)
    THEN
        SELECT "Такой комнаты не существует" AS Error;
        LEAVE Executioner;
    END IF;

    /*Проверка на правильность ввода ID карты*/
    IF NOT EXISTS (SELECT * FROM MonsterCards
                    WHERE ID_CardInGame = CardID)
    THEN
        SELECT "Такой карты не существует" AS Error;
        LEAVE Executioner;
    END IF;

    /*Является ли игрок текущим ходящим*/
    IF NOT EXISTS (SELECT * FROM Moves
                    JOIN Players ON Moves.ID_Player = Players.ID
                    JOIN Tokens ON Players.Login = Tokens.login
                    WHERE ID_Player = PlayerID AND token = tkn)
    THEN
        SELECT "Сейчас не твой ход" AS Error;
        LEAVE Executioner;
    END IF;

    /*Проверка на возможность активации*/
    IF NOT EXISTS (SELECT * FROM Monsters
                JOIN Players ON Monsters.ID_Player = Players.ID
                WHERE ID_Player != PlayerID AND ID_Room = RoomID)
    THEN
        SELECT "Невозможно активировать способность. Следующий ход" AS Error;

        /*Все остальные способности монстра использованы*/
        UPDATE MonsterCards SET AbilityIsBeingUsed = "YES"
            WHERE ID_Monster = monst;

        /*Если это 2 действие за ход*/
        IF EXISTS (SELECT * FROM Moves
                    JOIN Players ON Moves.ID_Player = Players.ID
                    JOIN Tokens ON Players.Login = Tokens.login
                    WHERE RemainingSteps = 1 AND ID_Player = PlayerID AND token = tkn)
        THEN
            /*Убрать текущего игрока из таблицы Moves*/
            DELETE Moves FROM Moves
                JOIN Players ON PlayerDeck.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE ID_Player = PlayerID AND token = tkn;

            /*Изменить следующего ходящего*/

            /*Если это последнее место в комнате*/
            IF Seat = (SELECT MaxSeats FROM Rooms
                        WHERE ID = RoomID)
            THEN
                /*Возвращаемся к 1 месту*/
                INSERT INTO Moves(ID_Player, RemainingSteps, Deadline) SELECT NowPlayer, "2", DATE_ADD(NOW(), INTERVAL TimeToStep SECOND) FROM Rooms;
            ELSE
                /*Двигаемся дальше по порядку*/
                SET Seat = Seat + 1;
                SET NowPlayer = (SELECT ID_Player FROM Players
                                    WHERE SeatNumber = Seat AND ID_Room = RoomID);
                INSERT INTO Moves(ID_Player, RemainingSteps, Deadline) SELECT NowPlayer, "2", DATE_ADD(NOW(), INTERVAL TimeToStep SECOND) FROM Rooms;
            END IF;
        END IF;

        LEAVE Executioner;
    END IF;

    /*Является ли выбранная карта чужой*/
    IF NOT EXISTS (SELECT * FROM MonsterCards
                    JOIN Monsters ON MonsterCards.ID_Monster = Monsters.ID
                    JOIN Players ON Monsters.ID_Player = Players.ID
                    WHERE ID_CardInGame = CardID AND ID_Player != PlayerID)
    THEN
        SELECT "Это твоя карта. Выбери чужую" AS Error;
        LEAVE Executioner;
    END IF;

    /*Является ли выбранная карта верхней*/
    IF partBody = "Голова"
    THEN
        /*Добавить выбранную карту в таблицу PlayerDeck текущему игроку*/
        INSERT INTO PlayerDeck(ID_Card, ID_Player, CardIsDiscarded) VALUES(CardID, PlayerID, "NO");

        /*Удалить выбранную карту у игрока, у которого ее забрали*/
        DELETE FROM PlayerDeck
            WHERE ID_Card = CardID AND ID_Player = plID;
    ELSE 
        IF partBody = "Туловище"
        THEN
            IF EXISTS(SELECT * FROM UsedParts
                        JOIN MonsterCards ON UsedParts.ID_Card = MonsterCards.ID_CardInGame
                        WHERE ID_Monster = MonsterID AND UsedParts NOT IN ("Голова"))
            THEN
                /*Добавить выбранную карту в таблицу PlayerDeck текущему игроку*/
                INSERT INTO PlayerDeck(ID_Card, ID_Player, CardIsDiscarded) VALUES(CardID, PlayerID, "NO");

                /*Удалить выбранную карту у игрока, у которого ее забрали*/
                DELETE FROM PlayerDeck
                    WHERE ID_Card = CardID AND ID_Player = plID;
            ELSE
                SELECT "Это не верхняя карта Монстра. Выберите другую" AS Error;
                LEAVE Executioner;
            END IF;         
        ELSE
            IF partBody = "Ноги"
            THEN
                IF EXISTS(SELECT * FROM UsedParts
                        JOIN MonsterCards ON UsedParts.ID_Card = MonsterCards.ID_CardInGame
                        WHERE ID_Monster = MonsterID AND UsedParts NOT IN ("Голова", "Туловище"))
                THEN
                    /*Добавить выбранную карту в таблицу PlayerDeck текущему игроку*/
                    INSERT INTO PlayerDeck(ID_Card, ID_Player, CardIsDiscarded) VALUES(CardID, PlayerID, "NO");

                    /*Удалить выбранную карту у игрока, у которого ее забрали*/
                    DELETE FROM PlayerDeck
                        WHERE ID_Card = CardID AND ID_Player = plID;
                ELSE
                    SELECT "Это не верхняя карта Монстра. Выберите другую" AS Error;
                    LEAVE Executioner;
                END IF;
            END IF;
        END IF;
    END IF;
END;