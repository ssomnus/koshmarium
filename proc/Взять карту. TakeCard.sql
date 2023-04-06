DROP PROCEDURE IF EXISTS TakeCard;
CREATE PROCEDURE TakeCard (tkn int(10) unsigned, PlayerID INT, RoomID INT)
COMMENT "Взять карту (токен, ID игрока, ID комнаты)"
TakeCard: BEGIN
    DECLARE crd INT DEFAULT(SELECT CardsFirstStep.ID_Card FROM CardsFirstStep
                            JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                            JOIN Players ON PlayerDeck.ID_Player = Players.ID
                            WHERE ID_Player = PlayerID);

    /*Переменная для узнавания ID карты за 1 действие*/
    DECLARE CardID INT;

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
        LEAVE TakeCard;
    END IF;
    
    /*Проверка на правильность ввода ID игрока*/
    IF NOT EXISTS (SELECT * FROM Players 
                    WHERE ID = PlayerID)
    THEN
        SELECT "Такого ID игрока не существует" AS Error;
        LEAVE TakeCard;
    END IF;

    /*Проверка на правильность ввода ID комнаты*/
    IF NOT EXISTS (SELECT * FROM Rooms 
                    WHERE ID = RoomID)
    THEN
        SELECT "Такой комнаты не существует" AS Error;
        LEAVE TakeCard;
    END IF;

    /*Является ли игрок текущим ходящим*/
    IF NOT EXISTS (SELECT * FROM Moves
                    JOIN Players ON Moves.ID_Player = Players.ID
                    WHERE ID_Player = PlayerID)
    THEN
        SELECT "Сейчас не твой ход" AS Error;
        LEAVE TakeCard;
    END IF;

    /*Нет неразыгранных способностей монстра*/
            SELECT 1;

    IF EXISTS (SELECT COUNT(ID_CardInGame) AS cnt FROM MonsterCards
                    JOIN Monsters ON MonsterCards.ID_Monster = Monsters.ID
                    JOIN Players ON Monsters.ID_Player = Players.ID
                    WHERE AbilityIsBeingUsed = "0" AND ID_Player = PlayerID
                    GROUP BY ID_Monster
                    HAVING cnt = 3)
    THEN
        SELECT "Способности монстра еще не разыграны" AS Error;
        LEAVE TakeCard;
    END IF;

    /*Не выбираются карты для сброса*/
            SELECT 2;

    IF EXISTS (SELECT * FROM PlayerDeck
                JOIN Players ON PlayerDeck.ID_Player = Players.ID
                WHERE CardIsDiscarded = "1" AND PlayerDeck.ID_Player = PlayerID)
    THEN
        SELECT "Выбираются карты для сброса" AS Error;
        LEAVE TakeCard;
    END IF;

    /*Добавить карту в таблицу PlayerDeck*/

    INSERT INTO PlayerDeck(ID_Card, ID_Player, CardIsDiscarded) SELECT ID_CardInGame, PlayerID, "NO" FROM CommonDeck 
        LIMIT 1;

    /*Удаление новой карты из таблицы CommonDeck*/

    DELETE CommonDeck FROM CommonDeck
        JOIN PlayerDeck ON CommonDeck.ID_CardInGame = PlayerDeck.ID_Card
        JOIN Players ON PlayerDeck.ID_Player = ID
        JOIN Tokens ON Players.Login = Tokens.login
        WHERE ID_CardInGame = ID_Card AND ID_Player = PlayerID AND token = tkn;

    /*Если это 1 действие за ход*/

    IF EXISTS (SELECT * FROM Moves
                JOIN Players ON Moves.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE RemainingSteps = "2" AND ID_Player = PlayerID AND token = tkn)
    THEN

        /*Изменить оставшееся количество действий*/
        UPDATE Moves 
            JOIN Players ON Moves.ID_Player = Players.ID
            SET RemainingSteps = "1"
            WHERE ID_Player = PlayerID;

    /*Это 2 действие за ход*/
    ELSE

        /*Если 1 действием за ход было выложить карту*/
        IF EXISTS (SELECT * FROM CardsFirstStep
                    JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                    JOIN Players ON PlayerDeck.ID_Player = Players.ID
                    WHERE ID_Player = PlayerID)
        THEN

            /*Узнаем ее значение*/
            SET CardID = crd;

            /*Удаляем из таблицы CardsFirstStep карту, которая там была*/
            DELETE CardsFirstStep FROM CardsFirstStep
                JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                JOIN Players ON PlayerDeck.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE CardsFirstStep.ID_Card = CardID AND ID_Player = PlayerID AND token = tkn;
                                
            /*Удаляем эту карту из таблицы PlayerDeck*/
            DELETE PlayerDeck FROM PlayerDeck
                JOIN Players ON PlayerDeck.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE ID_Card = CardID AND ID_Player = PlayerID AND token = tkn;
        END IF;

        /*Изменить оставшееся количество действий*/

        UPDATE Moves
            JOIN Players ON Moves.ID_Player = Players.ID
            SET RemainingSteps = "0"
            WHERE ID_Player = PlayerID;

        /*Убрать текущего игрока из таблицы Moves*/
        DELETE Moves FROM Moves
            JOIN Players ON Moves.ID_Player = Players.ID
            WHERE ID_Player = PlayerID;

        /*Изменить следующего ходящего*/

        /*Если это последнее место в комнате*/

        IF Seat = (SELECT MaxSeats FROM Rooms
                    WHERE ID = RoomID)
        THEN

            /*Возвращаемся к 1 месту*/
            INSERT INTO Moves(ID_Player, RemainingSteps, Deadline) SELECT NowPlayer, "2", DATE_ADD(NOW(), INTERVAL TimeToStep SECOND) FROM Rooms
                WHERE ID = RoomID;
        ELSE

            /*Двигаемся дальше по порядку*/
            SET Seat = Seat + 1;
            SET NowPlayer = (SELECT ID FROM Players
                                WHERE SeatNumber = Seat AND ID_Room = RoomID);
            INSERT INTO Moves(ID_Player, RemainingSteps, Deadline) SELECT NowPlayer, "2", DATE_ADD(NOW(), INTERVAL TimeToStep SECOND) FROM Rooms
                WHERE ID = RoomID;
        END IF;
    END IF;
END;