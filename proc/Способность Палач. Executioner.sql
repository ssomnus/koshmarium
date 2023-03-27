CREATE PROCEDURE Executioner(tkn INT, PlayerID INT, RoomID INT, CardID INT, MonsterID INT)
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

        /*Все остальные способности монстра использованы: для этого надо передать ID монстра*/

        /*Ход переходит к следующему игроку*/

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
    IF EXISTS (SELECT * FROM UsedParts
                JOIN MonsterCards ON UsedParts.ID_Card = MonsterCards.ID_CardInGame
                WHERE (NameBodyPart = "Голова") OR (NameBodyPart = "Туловище") OR (NameBodyPart = "Ноги"))
    
    /*Добавить выбранную карту в таблицу PlayerDeck текущему игроку*/
    INSERT INTO PlayerDeck(ID_Card, ID_Player, CardIsDiscarded) VALUES(CardID, PlayerID, "NO");

    /*Удалить выбранную карту у игрока, у которого ее забрали*/
    DELETE FROM PlayerDeck
            WHERE ID_Card = CardID AND ID_Player = plID;
END;