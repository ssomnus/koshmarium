DROP PROCEDURE IF EXISTS DiscardAndTakeCard;
CREATE PROCEDURE DiscardAndTakeCard(tkn int(10) unsigned, PlayerID INT, RoomID INT)
COMMENT "Сбросить и взять новые карты из колоды (токен, ID игрока, ID комнаты)"
DiscardAndTakeCard: BEGIN
    /*Подсчет количества карт для сброса*/
    DECLARE discard INT DEFAULT (SELECT COUNT(ID_Card) AS cnt FROM PlayerDeck
                                    JOIN Players ON PlayerDeck.ID_Player = Players.ID
                                    JOIN Tokens ON Players.Login = Tokens.login
                                    WHERE CardIsDiscarded = "1" AND ID_Player = PlayerID AND token = tkn);

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
        LEAVE DiscardAndTakeCard;
    END IF;

    /*Проверка на правильность ввода ID игрока*/
    IF NOT EXISTS (SELECT * FROM Players
                    WHERE ID = PlayerID)
    THEN
        SELECT "Такого ID игрока не существует" AS Error;
        LEAVE DiscardAndTakeCard;
    END IF;

    /*Проверка на правильность ввода ID комнаты*/
    IF NOT EXISTS (SELECT * FROM Rooms 
                    WHERE ID = RoomID)
    THEN
        SELECT "Такой комнаты не существует" AS Error;
        LEAVE DiscardAndTakeCard;
    END IF;

    /*Есть ли выбранные карты для сброса*/
    IF discard = 0
    THEN
        SELECT "У вас нет карт для сброса" AS Error;
        LEAVE DiscardAndTakeCard;
    END IF;

    /*Количество карт для добавления взамен сброшенных*/
    SET discard = discard / 2;

    SELECT 1;
    /*Добавление карт в таблицу PlayerDeck*/
    INSERT INTO PlayerDeck(ID_Card, ID_Player, CardIsDiscarded) SELECT ID_CardInGame, PlayerID, "0" FROM CommonDeck
        LIMIT discard;
                
    SELECT 2;
    /*Удаление этих карт из таблицы CommonDeck*/
    DELETE CommonDeck FROM CommonDeck
        JOIN PlayerDeck ON CommonDeck.ID_CardInGame = PlayerDeck.ID_Card
        JOIN Players ON PlayerDeck.ID_Player = Players.ID
        WHERE ID_CardInGame = ID_Card AND ID_Player = PlayerID;
                
    SELECT 3;
    /*Удаление сброшенных карт*/
    DELETE PlayerDeck FROM PlayerDeck
        JOIN Players ON PlayerDeck.ID_Player = Players.ID
        WHERE CardIsDiscarded = "1" AND ID_Player = PlayerID;

    SELECT 4;
    /*Если это 1 действие за ход*/
    IF EXISTS (SELECT * FROM Moves
                JOIN Players ON Moves.ID_Player = Players.ID
                WHERE RemainingSteps = "2" AND ID = PlayerID)
    THEN
    SELECT 5;
        /*Изменить оставшееся количество действий*/
        UPDATE Moves
            JOIN Players ON Moves.ID_Player = Players.ID
            SET RemainingSteps = "1"
            WHERE ID_Player = PlayerID;
            SELECT 6;
    /*Это 2 действие за ход*/
    ELSE
        SELECT 7;
        /*Если 1 действием за ход было выложить карту*/
        IF EXISTS (SELECT * FROM CardsFirstStep
                    JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                    JOIN Players ON PlayerDeck.ID_Player = Players.ID
                    WHERE ID_Player = PlayerID)
        THEN
        SELECT 8;
            /*Узнаем ее значение*/
            SET CardID = (SELECT ID_Card FROM CardsFirstStep
                            JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                            JOIN Players ON PlayerDeck.ID_Player = Players.ID
                            WHERE ID_Player = PlayerID);

            SELECT 9;
            /*Удаляем из таблицы CardsFirstStep карту, которая там была*/
            DELETE CardsFirstStep FROM CardsFirstStep
                JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                JOIN Players ON PlayerDeck.ID_Player = Players.ID
                WHERE ID_Card = CardID AND ID_Player = PlayerID;
                                
            SELECT 10;
            /*Удаляем эту карту из таблицы PlayerDeck*/
            DELETE PlayerDeck FROM PlayerDeck
                JOIN Players ON PlayerDeck.ID_Player = Players.ID
                WHERE ID_Card = CardID AND ID_Player = PlayerID;
        END IF;

        SELECT 11;
        /*Изменить оставшееся количество действий*/
        UPDATE Moves
            JOIN Players ON Moves.ID_Player = Players.ID
            SET RemainingSteps = "0"
            WHERE ID_Player = PlayerID;

        SELECT 12;
        /*Убрать текущего игрока из таблицы Moves*/
        DELETE Moves FROM Moves
            WHERE ID_Player = PlayerID;

        /*Изменить следующего ходящего*/

        /*Если это последнее место в комнате*/
                SELECT 13;

        IF Seat = (SELECT MaxSeats FROM Rooms
                    WHERE ID = RoomID)
        THEN
                SELECT 14;

            /*Возвращаемся к 1 месту*/
            INSERT INTO Moves(ID_Player, RemainingSteps, Deadline) SELECT NowPlayer, "2", DATE_ADD(NOW(), INTERVAL TimeToStep SECOND) FROM Rooms
                WHERE ID = RoomID;
                SELECT 15;
        ELSE
            SELECT 16;

            /*Двигаемся дальше по порядку*/
            SET Seat = Seat + 1;
            SELECT 17;
            SET NowPlayer = (SELECT ID FROM Players
                                WHERE SeatNumber = Seat AND ID_Room = RoomID);
                                SELECT 18;
            INSERT INTO Moves(ID_Player, RemainingSteps, Deadline) SELECT NowPlayer, "2", DATE_ADD(NOW(), INTERVAL TimeToStep SECOND) FROM Rooms
                WHERE ID = RoomID;
                SELECT 19;
        END IF;
    END IF;
END;