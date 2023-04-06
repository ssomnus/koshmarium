CREATE PROCEDURE Eater(tkn int(10) unsigned, PlayerID INT, CardID INT, MonsterID INT)
COMMENT "Способность Пожиратель (токен, ID игрока, ID карты, ID монстра)"
Eater: BEGIN
    /*Переменная для нахождения ID комнаты*/
    DECLARE IDRoom INT DEFAULT (SELECT Rooms.ID FROM Rooms
                                    JOIN Players ON Rooms.ID = Players.ID_Room
                                    WHERE PlayerID = Players.ID);

    /*Является ли игрок текущим ходящим*/
    IF NOT EXISTS (SELECT * FROM Moves
                JOIN Players ON Moves.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE ID_Player = PlayerID AND token = tkn)
    THEN
        SELECT "Сейчас не твой ход" AS Error;
        LEAVE Eater;
    END IF;

    /*Проверка на возможность активации*/
    IF NOT EXISTS (SELECT COUNT(ID_CardInGame) AS cnt FROM MonsterCards
                    JOIN Monsters ON MonsterCards.ID_Monster = Monsters.ID
                    JOIN Players ON Monsters.ID_Player = Players.ID
                    GROUP BY ID_Monster
                    HAVING cnt > 0 AND ID_Player = PlayerID AND ID_Room = IDRoom)
    THEN
        SELECT "Невозможно активировать способность. Следующий ход" AS Error;
        LEAVE Eater;
    END IF;

    /*Является ли выбранное существо своим*/
    IF NOT EXISTS (SELECT * FROM Monsters
                    JOIN Players ON Monsters.ID_Player = Players.ID
                    JOIN Rooms ON Players.ID_Room = Rooms.ID
                    WHERE IDRoom = Rooms.ID AND Players.ID = PlayerID)
    THEN
        SELECT "У тебя нет такого монстра" AS Error;
        LEAVE Eater;
    END IF;

    /*Сбросить выбранную карту*/
    DELETE FROM MonsterCards
        WHERE ID_CardInGame = CardID AND ID_Monster = MonsterID;
END;