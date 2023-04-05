DROP PROCEDURE IF EXISTS DiscardAndTakeCard;
CREATE PROCEDURE DiscardAndTakeCard(tkn INT, PlayerID INT, RoomID INT)
COMMENT "Сбросить и взять новые карты из колоды (токен, ID игрока, ID комнаты)"
DiscardAndTakeCard: BEGIN
    /*Подсчет количества карт для сброса*/
    DECLARE discard INT DEFAULT (SELECT COUNT(ID_Card) AS cnt FROM PlayerDeck
                                    JOIN Players ON PlayerDeck.ID_Player = Players.ID
                                    JOIN Tokens ON Players.Login = Tokens.login
                                    WHERE CardIsDiscarded = "YES" AND ID_Player = PlayerID AND token = tkn);

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

    /*Добавление карт в таблицу PlayerDeck*/
    INSERT INTO PlayerDeck(ID_Card, ID_Player, CardIsDiscarded) SELECT ID_CardInGame, PlayerID, "NO" FROM CommonDeck
        LIMIT discard;
                
    /*Удаление этих карт из таблицы CommonDeck*/
    DELETE CommonDeck FROM CommonDeck
        JOIN PlayerDeck ON CommonDeck.ID_CardInGame = PlayerDeck.ID_Card
        JOIN Players ON PlayerDeck.ID_Player = Players.ID
        JOIN Tokens ON Players.Login = Tokens.login
        WHERE ID_CardInGame = ID_Card AND ID_Player = PlayerID AND token = tkn;
                
    /*Удаление сброшенных карт*/
    DELETE PlayerDeck FROM PlayerDeck
        JOIN Players ON PlayerDeck.ID_Player = Players.ID
        JOIN Tokens ON Players.Login = Tokens.login
        WHERE CardIsDiscarded = "YES" AND ID_Player = PlayerID AND token = tkn;

    /*Если это 1 действие за ход*/
    IF EXISTS (SELECT * FROM Moves
                JOIN Players ON Moves.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE RemainingSteps = 2 AND ID = PlayerID AND token = tkn)
    THEN
        /*Изменить оставшееся количество действий*/
        UPDATE Moves
            JOIN Players ON Moves.ID_Player = Players.ID
            JOIN Tokens ON Players.Login = Tokens.login
            SET RemainingSteps = 1
            WHERE ID_Player = PlayerID AND token = tkn;
            
    /*Это 2 действие за ход*/
    ELSE
        /*Если 1 действием за ход было выложить карту*/
        IF EXISTS (SELECT * FROM CardsFirstStep
                    JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                    JOIN Players ON PlayerDeck.ID_Player = Players.ID
                    JOIN Tokens ON Players.Login = Tokens.login
                    WHERE ID_Player = PlayerID AND token = tkn)
        THEN
            /*Узнаем ее значение*/
            SET CardID = (SELECT ID_Card FROM CardsFirstStep
                            JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                            JOIN Players ON PlayerDeck.ID_Player = Players.ID
                            JOIN Tokens ON Players.Login = Tokens.login
                            WHERE ID_Player = PlayerID AND token = tkn);

            /*Удаляем из таблицы CardsFirstStep карту, которая там была*/
            DELETE CardsFirstStep FROM CardsFirstStep
                JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                JOIN Players ON PlayerDeck.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE ID_Card = CardID AND ID_Player = PlayerID AND token = tkn;
                                
            /*Удаляем эту карту из таблицы PlayerDeck*/
            DELETE PlayerDeck FROM PlayerDeck
                JOIN Players ON PlayerDeck.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE ID_Card = CardID AND ID_Player = PlayerID AND token = tkn;
        END IF;

        /*Изменить оставшееся количество действий*/
        UPDATE Moves
            JOIN Players ON Moves.ID_Player = Players.ID
            JOIN Tokens ON Players.Login = Tokens.login
            SET RemainingSteps = 0
            WHERE ID_Player = PlayerID AND token = tkn;

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
END;