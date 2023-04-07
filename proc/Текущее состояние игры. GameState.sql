DROP PROCEDURE IF EXISTS GameState;
CREATE PROCEDURE GameState(tkn int(10) unsigned, PlayerID INT, RoomID INT)
COMMENT "Вывести текущее состояние игры (токен, ID игрока, ID комнаты)"
GameState: BEGIN

    DECLARE crd INT DEFAULT(SELECT CardsFirstStep.ID_Card FROM CardsFirstStep
                                JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                                JOIN Players ON PlayerDeck.ID_Player = Players.ID
                                WHERE ID_Player = PlayerID);

    /*Переменная для узнавания места*/
    DECLARE Seat INT DEFAULT(SELECT SeatNumber FROM Moves
                                JOIN Players ON Moves.ID_Player = Players.ID
                                WHERE ID_Room = RoomID);

    /*Переменная для определения ID следующего ходящего*/
    DECLARE NowPlayer INT DEFAULT(SELECT ID FROM Players
                                        WHERE ID_Room = RoomID AND SeatNumber = 1);

    /*Принадлежит ли токен игроку*/
    IF NOT EXISTS(SELECT * FROM Tokens
                    JOIN Players ON Tokens.login = Players.Login
                    WHERE ID = PlayerID AND token = tkn)
    THEN
        SELECT "Это не ваш токен" AS Error;
        LEAVE GameState;
    END IF;
    
    /*Проверка на правильность ввода ID игрока*/
    IF NOT EXISTS (SELECT * FROM Players 
                    WHERE ID = PlayerID)
    THEN
        SELECT "Такого ID игрока не существует" AS Error;
        LEAVE GameState;
    END IF;

    /*Проверка на правильность ввода ID комнаты*/
    IF NOT EXISTS (SELECT * FROM Rooms
                    WHERE Rooms.ID = RoomID)
    THEN
        SELECT "Такого ID комнаты не существует" AS Error;
        LEAVE GameState;
    END IF;

    /*(1)Инфо об игроках в комнате: ID, логин, номер места, количество собранных монстров*/
    SELECT Players.ID AS ID_Player, Login, SeatNumber FROM Players
        WHERE ID_Room = RoomID
        ORDER BY SeatNumber;

    /*(2)Инфо о текущем ходящем: ID, логин, время на ход, оставшееся колво действий*/
    SELECT ID_Player, Login, TIMESTAMPDIFF(SECOND, NOW(), Deadline) AS Deadline, RemainingSteps FROM Moves
        JOIN Players ON Moves.ID_Player = Players.ID
        WHERE ID_Room = RoomID;

    /*(3)Карта за первое действие текущего ходящего*/
    SELECT CardsFirstStep.ID_Card AS ID_Card, Legion FROM CardsFirstStep
        JOIN CardsInGame ON CardsFirstStep.ID_Card = CardsInGame.ID
        JOIN Cards ON CardsInGame.ID_Card = Cards.ID
        JOIN PlayerDeck ON CardsInGame.ID = PlayerDeck.ID_Card
        JOIN Players ON PlayerDeck.ID_Player = Players.ID
        WHERE ID_Room = RoomID;

    /*(4)Инфо о поле: ID монстра, из каких карт состоит монстр (легион, часть тела, способность), кому он принадлежит*/
    SELECT ID_Player, Monsters.ID AS ID_Monster, ID_CardInGame, NameBodyPart, Legion, Ability, Cards.ID FROM MonsterCards
        JOIN Monsters ON MonsterCards.ID_Monster = Monsters.ID /*связующее звено*/
        JOIN Players ON Monsters.ID_Player = Players.ID /*вытаскиваем комнату для проверки*/
        JOIN CardsInGame ON MonsterCards.ID_CardInGame = CardsInGame.ID /*связующее звено*/
        JOIN Cards ON CardsInGame.ID_Card = Cards.ID /*легион, способности*/
        LEFT JOIN UsedParts ON CardsInGame.ID = UsedParts.ID_Card /*использованная часть тела*/
        WHERE ID_Room = RoomID
        ORDER BY MonsterCards.ID_Monster, ID_CardInGame;

    /*(5)Монстры игрока*/
    SELECT Monsters.ID AS ID_Monster FROM Monsters
        JOIN Players ON Monsters.ID_Player = Players.ID
        WHERE ID_Player = PlayerID;

    /*(6)Вывести для игрока его колоду карт*/
    SELECT PlayerDeck.ID_Card AS ID_Card, PartName, Legion, Ability, CardIsDiscarded, Cards.ID FROM PlayerDeck
        JOIN CardsInGame ON PlayerDeck.ID_Card = CardsInGame.ID
        JOIN Cards ON CardsInGame.ID_Card = Cards.ID /*Способность, Легион*/
        JOIN BodyPartsOfCard ON Cards.ID = BodyPartsOfCard.ID_Card /*Часть тела, сброшена ли*/
        JOIN Players ON PlayerDeck.ID_Player = Players.ID
        WHERE ID_Player = PlayerID
        GROUP BY PlayerDeck.ID_Card;

    /*(7)Певчая колода для текущего игрока*/
    IF EXISTS (SELECT * FROM Moves
                JOIN Players ON Moves.ID_Player = Players.ID
                WHERE ID_Player = PlayerID)
    THEN
        SELECT ChoristerDeck.ID_Card AS ID_Card, PartName, Legion, Ability, CardIsDiscarded FROM ChoristerDeck
            JOIN CardsInGame ON ChoristerDeck.ID_Card = CardsInGame.ID
            JOIN Cards ON CardsInGame.ID_Card = Cards.ID
            JOIN BodyPartsOfCard ON Cards.ID = BodyPartsOfCard.ID_Card
            JOIN PlayerDeck ON CardsInGame.ID = PlayerDeck.ID_Card
            JOIN Players ON PlayerDeck.ID_Player = Players.ID
            WHERE ID_Room = RoomID;
    END IF;

    /*Проверка на истечение времени*/
    IF EXISTS (SELECT COUNT(ID_CardInGame) AS cnt FROM MonsterCards
                WHERE AbilityIsBeingUsed = "0"
                GROUP BY ID_Monster
                HAVING cnt != 3)
    THEN
        /*Проверка на истечение времени*/
        IF EXISTS(SELECT * FROM Moves
                    JOIN Players ON Moves.ID_Player = Players.ID
                    WHERE ID_Room = RoomID AND NOW() >= Deadline)
        THEN
            /*Убрать текущего игрока из таблицы Moves*/
            DELETE Moves FROM Moves
                JOIN Players ON Moves.ID_Player = Players.ID
                WHERE ID_Room = RoomID;

            /*Если 1 действием за ход было выложить карту*/
            IF EXISTS (SELECT * FROM CardsFirstStep
                        JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                        JOIN Players ON PlayerDeck.ID_Player = Players.ID
                        WHERE ID_Player = PlayerID)
            THEN
                /*Удаляем из таблицы CardsFirstStep карту, которая там была*/
                DELETE CardsFirstStep FROM CardsFirstStep
                    JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                    JOIN Players ON PlayerDeck.ID_Player = Players.ID
                    WHERE CardsFirstStep.ID_Card = crd AND ID_Player = PlayerID;
                                    
                /*Удаляем эту карту из таблицы PlayerDeck*/
                DELETE PlayerDeck FROM PlayerDeck
                    JOIN Players ON PlayerDeck.ID_Player = Players.ID
                    JOIN Tokens ON Players.Login = Tokens.login
                    WHERE ID_Card = crd AND ID_Player = PlayerID AND token = tkn;
            END IF;

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
    END IF;

    /*Проверка на победу*/
    IF 15 = (SELECT COUNT(ID_CardInGame) AS cnt FROM MonsterCards
                JOIN Monsters ON MonsterCards.ID_Monster = Monsters.ID
                GROUP BY ID_Player
                HAVING ID_Player = PlayerID)
    THEN
        /*Вывод на победу*/
        SELECT "Игра завершена. Ваш соперник выложил все карты в Монстров" AS Win;

        /*Удаляем текущего ходящего*/
        DELETE Moves FROM Moves
            JOIN Players ON Moves.ID_Player = Players.ID
            WHERE ID_Room = RoomID;
        
        /*Удаляем колоды игроков в комнате*/
        DELETE PlayerDeck FROM PlayerDeck
            JOIN Players ON PlayerDeck.ID_Player = Players.ID
            WHERE ID_Room = RoomID;
    END IF;

END;