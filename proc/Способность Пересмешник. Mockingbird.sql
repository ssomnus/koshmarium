CREATE PROCEDURE Mockingbird(tkn INT, PlayerID INT, CardID INT, MonsterID INT, RoomID INT)
COMMENT "Способность Пересмешник (токен, ID игрока, ID монстра, )"
Mockingbird: BEGIN

    /*Является ли игрок текущим ходящим*/
    IF NOT EXISTS (SELECT * FROM Moves
                JOIN Players ON Moves.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE ID_Player = PlayerID AND token = tkn)
    THEN
        SELECT "Сейчас не твой ход" AS Error;
        LEAVE Mockingbird;
    END IF;

    /*Проверка на возможность активации*/
    IF NOT EXISTS (SELECT COUNT(ID_CardInGame) AS cnt FROM MonsterCards
                    JOIN Monsters ON MonsterCards.ID_Monster = Monsters.ID
                    JOIN Players ON Monsters.ID_Player = Players.ID
                    GROUP BY ID_Monster
                    HAVING cnt != 3 AND ID_Player != PlayerID AND ID_Room = IDRoom)
    THEN
        SELECT "Невозможно активировать способность. Следующий ход" AS Error;
        LEAVE Mockingbird;
    END IF;

    /*Добавить карту в таблицу MonstersCard*/
    INSERT INTO MonsterCards(ID_CardInGame, ID_Monster, AbilityIsBeingUsed) VALUES(CardID, MonsterID, "NO");

    /*Удалить эту карту из таблицы*/
    DELETE FROM PlayerDeck
        WHERE ID_Card = CardID AND ID_Player = PlayerID;
END;