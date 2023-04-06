DROP PROCEDURE IF EXISTS Scavenger;
CREATE PROCEDURE Scavenger(tkn int(10) unsigned, PlayerID INT, RoomID INT, MonsterID INT)
COMMENT "Способность Падальщик (токен, ID игрока, ID монстра)"
Scavenger: BEGIN
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

    DECLARE abilCardID INT DEFAULT(SELECT NameBodyPart FROM UsedParts
                                    JOIN MonsterCards ON UsedParts.ID_Card = MonsterCards.ID_CardInGame
                                    WHERE ID_Monster = monst AND AbilityIsBeingUsed = "YES");
    
    /*Определение ID карты, которая вызвала эту способность */
    DECLARE cardAbility INT DEFAULT(SELECT ID_CardInGame FROM MonsterCards
                                        JOIN CardsInGame ON
                                        JOIN Cards ON
                                        WHERE ID_Monster = monst AND AbilityIsBeingUsed = "NO" AND Ability = "Падальщик" AND );

    /*Проверка на правильность ввода токена*/
    IF NOT EXISTS (SELECT * FROM Tokens 
                    WHERE token = tkn)
    THEN
        SELECT "Такого токена не существует" AS Error;
        LEAVE Scavenger;
    END IF;

    /*Проверка на правильность ввода ID игрока*/
    IF NOT EXISTS (SELECT * FROM Players 
                    WHERE ID = PlayerID)
    THEN
        SELECT "Такого ID игрока не существует" AS Error;
        LEAVE Scavenger;
    END IF;

    /*Проверка на правильность ввода ID комнаты*/
    IF NOT EXISTS (SELECT * FROM Rooms 
                    WHERE ID = RoomID)
    THEN
        SELECT "Такой комнаты не существует" AS Error;
        LEAVE Scavenger;
    END IF;

    /*Проверка на правильность ввода ID монстра*/
    IF NOT EXISTS (SELECT * FROM Monsters 
                    WHERE ID = MonsterID)
    THEN
        SELECT "Такого Монстра не существует" AS Error;
        LEAVE Scavenger;
    END IF;

    /*Является ли игрок текущим ходящим*/
    IF NOT EXISTS (SELECT * FROM Moves
                JOIN Players ON Moves.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE ID_Player = PlayerID AND token = tkn)
    THEN
        SELECT "Сейчас не твой ход" AS Error;
        LEAVE Scavenger;
    END IF;

    /*Проверка на возможность активации*/
    IF NOT EXISTS (SELECT COUNT(ID_CardInGame) AS cnt FROM MonsterCards
                    JOIN Monsters ON MonsterCards.ID_Monster = Monsters.ID
                    JOIN Players ON Monsters.ID_Player = Players.ID
                    GROUP BY ID_Monster
                    HAVING cnt != 3 AND ID_Player != PlayerID AND ID_Room = IDRoom)
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

        LEAVE Scavenger;
    END IF;

    /*Является ли выбранный монстр чужим*/
    IF NOT EXISTS (SELECT * FROM Monsters
                    JOIN Players ON Monsters.ID_Player = Players.ID
                    JOIN Rooms ON Players.ID_Room = Rooms.ID
                    WHERE Monsters.ID = MonsterID AND RoomID = Rooms.ID AND Players.ID != PlayerID)
    THEN
        SELECT "Это твой Монстр. Выбери чужого" AS Error;
        LEAVE Scavenger;
    END IF;

    /*Является ли выбранное существо незавершенным*/
    IF NOT EXISTS (SELECT COUNT(ID_CardInGame) AS cnt FROM MonsterCards
                    GROUP BY ID_Monster
                    HAVING ID_Monster = MonsterID AND cnt != 3)
    THEN
        SELECT "Этот монстр уже завершен" AS Error;
        LEAVE Scavenger;
    END IF;

    /*Удалить выбранного монстра*/
    DELETE FROM Monsters
        WHERE ID = MonsterID;

    /*Карта становится использованной*/
    UPDATE MonsterCards
        SET AbilityIsBeingUsed = "YES"
        WHERE ID_CardInGame = card;
END;