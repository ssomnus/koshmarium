DROP PROCEDURE IF EXISTS StayAtRoom;
CREATE PROCEDURE StayAtRoom (tkn int(10) unsigned, RoomID INT)
COMMENT "Ожидание противников в комнате (токен, ID комнаты)"
StayAtRoom: BEGIN
    /*Переменная для определения места*/
    DECLARE Seat INT DEFAULT(SELECT COUNT(ID) FROM Players
                                WHERE ID_Room = RoomID);

    /*Переменная для переноса ID игрока*/
    DECLARE PlayerID INT DEFAULT(SELECT ID FROM Players
                                    JOIN Tokens ON Players.Login = Tokens.login
                                    WHERE ID_Room = RoomID AND tkn = token);

    /*Переменная для определения первого ходящего*/
    DECLARE FirstPlayer INT DEFAULT 0;

    /*Проверка на правильность ввода токена*/
    IF NOT EXISTS (SELECT * FROM Tokens
                    WHERE token = tkn)
    THEN
        SELECT "Такого токена не существует" AS Error;
        LEAVE StayAtRoom;
    END IF;

    /*Проверка на правильность ввода ID комнаты*/
    IF NOT EXISTS (SELECT * FROM Rooms
                    WHERE ID = RoomID)
    THEN
        SELECT "Такого ID комнаты не существует" AS Error;
        LEAVE StayAtRoom;
    END IF;

    /*Проверка на заполненность комнаты*/
    IF EXISTS (SELECT * FROM Players
                JOIN Rooms ON Players.ID_Room = Rooms.ID
                WHERE ID_Room = RoomID AND MaxSeats = Seat)
    THEN
        /*Проверка на количество монстров*/
        IF EXISTS (SELECT COUNT(ID) AS cnt FROM Monsters
                WHERE ID_Player = PlayerID
                GROUP BY ID_Player
                HAVING cnt = 0)
        THEN
            /*создаем по 5 монстров каждому игроку*/
            INSERT INTO Monsters(ID, ID_Player) VALUES(NULL, PlayerID),
                                                        (NULL, PlayerID),
                                                        (NULL, PlayerID),
                                                        (NULL, PlayerID),
                                                        (NULL, PlayerID);
        END IF;

        IF NOT EXISTS(SELECT ID_Player FROM Moves
                        JOIN Players ON Moves.ID_Player = Players.ID
                        WHERE ID_Room = RoomID)
        THEN
            /*Определение игрока, начинающего игру*/
            SET FirstPlayer = (SELECT ID FROM Players 
                                    WHERE ID_Room = RoomID AND SeatNumber = 1);
                
            /*Начинает ходить игрок, сидящий на 1 месте*/
            INSERT INTO Moves(ID_Player, RemainingSteps, Deadline) SELECT FirstPlayer, "2", DATE_ADD(NOW(), INTERVAL TimeToStep SECOND) FROM Rooms
                WHERE ID = RoomID;
            SELECT * FROM Moves;
        END IF;
            
        /*Начинается игра*/
        CALL GameState(tkn, PlayerID, RoomID);
    ELSE
        /*Вывод всех игроков в комнате*/
        SELECT Players.ID AS ID_Player, Login, SeatNumber FROM Rooms
            JOIN Players ON Rooms.ID = Players.ID_Room
            WHERE ID_Room = RoomID;
    END IF;
END;