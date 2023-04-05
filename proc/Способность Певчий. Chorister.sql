CREATE PROCEDURE Chorister (tkn INT, PlayerID INT, RoomID INT, CardID INT, MonsterID INT)
COMMENT "Использовать способность Певчий (токен, ID игрока, ID комнаты, ID карты, ID монстр)"
Chorister: BEGIN
    /*Часть тела выбранной карты*/
    DECLARE part ENUM("Голова", "Туловище", "Ноги") DEFAULT(SELECT NameBodyPart FROM UsedParts
                                                            WHERE ID_Card = CardID);

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

    /*Проверка на правильность ввода токена*/
    IF NOT EXISTS (SELECT * FROM Tokens 
                    WHERE token = tkn)
    THEN
        SELECT "Такого токена не существует" AS Error;
        LEAVE Chorister;
    END IF;

    /*Проверка на правильность ввода ID игрока*/
    IF NOT EXISTS (SELECT * FROM Players 
                    WHERE ID = PlayerID)
    THEN
        SELECT "Такого ID игрока не существует" AS Error;
        LEAVE Chorister;
    END IF;

    /*Проверка на правильность ввода ID комнаты*/
    IF NOT EXISTS (SELECT * FROM Rooms 
                    WHERE ID = RoomID)
    THEN
        SELECT "Такой комнаты не существует" AS Error;
        LEAVE Chorister;
    END IF;

    /*Проверка на правильность ввода ID карты*/
    IF NOT EXISTS (SELECT * FROM CardsInGame 
                    WHERE ID = CardID)
    THEN
        SELECT "Такой карты не существует" AS Error;
        LEAVE Chorister;
    END IF;

    /*Проверка на правильность ввода ID монстра*/
    IF NOT EXISTS (SELECT * FROM Monsters
                    WHERE ID = MonsterID)
    THEN
        SELECT "Такого Монстра не существует" AS Error;
        LEAVE Chorister;
    END IF;

    /*Является ли игрок текущим ходящим*/
    IF NOT EXISTS (SELECT * FROM Moves
                    JOIN Players ON Moves.ID_Player = Players.ID
                    JOIN Tokens ON Players.Login = Tokens.login
                    WHERE ID_Player = PlayerID AND token = tkn)
    THEN
        SELECT "Сейчас не ваш ход" AS Error;
        LEAVE Chorister;
    END IF;

    /*Находятся ли эта карта в Певчей колоде*/
    IF NOT EXISTS (SELECT * FROM ChoristerDeck
                    WHERE ID_Card = CardID);
    THEN
        SELECT "Этой картой нельзя походить. Выберите карту из певчей колоды" AS Error;
        LEAVE Chorister;
    END IF;

    /*Принадлежит ли эта карта игроку*/
    IF NOT EXISTS (SELECT * FROM ChoristerDeck
                    JOIN PlayerDeck USING(ID_Card)
                    JOIN Players ON PlayerDeck.ID_Player = Players.ID
                    JOIN Tokens ON Players.Login = Tokens.login
                    WHERE ChoristerDeck.ID_Card = CardID AND ID_Player = PlayerID)
    THEN
        SELECT "У вас нет такой карты" AS Error;
        LEAVE Chorister;
    END IF;

    /*Проверка на возможность выложить по части тела*/
    IF NOT EXISTS (SELECT COUNT(ID) AS cnt FROM Monsters
                GROUP BY ID_Player
                HAVING cnt != 5 AND ID_Player = PlayerID)
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
    END IF;

    /*Проверка на завершение монстра*/
    IF EXISTS (SELECT COUNT(ID_CardInGame) AS cnt FROM MonsterCards
                GROUP BY ID_Monster
                HAVING cnt = 3 AND 3 = 
                                        (SELECT COUNT(AbilityIsBeingUsed) AS c_ab FROM MonsterCards GROUP BY ID_Monster HAVING AbilityIsBeingUsed = "YES")
                        )
    THEN
        /*Активация способности для головы*/
        IF "Голова" = (SELECT NameBodyPart FROM UsedParts
                        JOIN MonsterCards ON UsedParts.ID_Card = MonsterCards.ID_CardInGame
                        WHERE ID_Monster = MonsterID AND AbilityIsBeingUsed = "NO"
                        ORDER BY
                        LIMIT 1)
        THEN
            SELECT "Способность для головы" AS System;
            CALL ActivationAbility(tkn, PlayerID, CardID, MonsterID);
        END IF;

        /*Активация способности для тела*/
        IF "Туловище" = (SELECT NameBodyPart FROM UsedParts
                        JOIN MonsterCards ON UsedParts.ID_Card = MonsterCards.ID_CardInGame
                        WHERE ID_Monster = MonsterID
                        ORDER BY
                        LIMIT 1)
        THEN
            SELECT "Способность для туловища" AS System;
            CALL ActivationAbility(tkn, PlayerID, CardID, MonsterID);
        END IF;

        /*Активация способности для ног*/
        IF "Ноги" = (SELECT NameBodyPart FROM UsedParts
                        JOIN MonsterCards ON UsedParts.ID_Card = MonsterCards.ID_CardInGame
                        WHERE ID_Monster = MonsterID
                        ORDER BY
                        LIMIT 1)
        THEN
            SELECT "Способность для ног" AS System;
            CALL ActivationAbility(tkn, PlayerID, CardID, MonsterID);
        END IF;
    END IF;
END;