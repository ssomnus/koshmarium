CREATE PROCEDURE AllRooms ()
COMMENT "Вывести доступные игровые комнаты"
AllRooms: BEGIN
    /*Если в комнате есть свободные места*/
    IF EXISTS (SELECT COUNT(Players.ID) AS count_players, MaxSeats FROM Players 
                JOIN Rooms ON Players.ID_Room = Rooms.ID 
                GROUP BY ID_Room 
                HAVING MaxSeats != count_players)
    THEN
        /*Вывести инфу о комнате*/
        SELECT Rooms.ID AS ID_Room, MaxSeats, COUNT(Players.ID) AS count_players FROM Players 
            JOIN Rooms ON Players.ID_Room = Rooms.ID 
            GROUP BY ID_Room 
            HAVING MaxSeats != count_players;

        /*Если в комнате есть игроки*/
        IF EXISTS (SELECT COUNT(ID) AS cnt FROM Players 
                    GROUP BY ID_Room 
                    HAVING cnt > 0)
        THEN
            /*Вывести инфу о всех игроках в этих комнатах*/
            SELECT Rooms.ID AS ID_Room, SeatNumber, Players.ID AS ID_Player, Login FROM Players 
                JOIN Rooms ON Players.ID_Room = Rooms.ID;
        END IF;

    ELSE 
        SELECT "Свободных комнат нет" AS Error;
    END IF;
END;