CREATE PROCEDURE Scavenger(tkn INT, PlayerID INT, RoomID INT, MonsterID INT)
Scavenger: COMMENT "Способность Падальщик (токен, ID игрока, ID монстра)"
BEGIN
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
            WHERE ID_Monster = /*монстр, в котором была активирована эта способность*/;

        /*Ход переходит к следующему игроку*/

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
    
END;