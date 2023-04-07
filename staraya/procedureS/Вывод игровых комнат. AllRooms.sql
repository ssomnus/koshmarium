DROP PROCEDURE IF EXISTS AllRooms;
CREATE PROCEDURE AllRooms ()
COMMENT "Вывести доступные игровые комнаты"
AllRooms: BEGIN
    /*Если в комнате есть свободные места*/
    IF EXISTS (SELECT COUNT(Players.ID) AS count_players, MaxSeats FROM Rooms 
                LEFT JOIN Players ON Players.ID_Room = Rooms.ID 
                GROUP BY ID_Room 
                HAVING MaxSeats != count_players)
    THEN
        /*Вывести инфу о комнате*/
        SELECT Rooms.ID AS ID_Room, MaxSeats, COUNT(Players.ID) AS count_players FROM Players 
            JOIN Rooms ON Players.ID_Room = Rooms.ID 
            GROUP BY ID_Room 
            HAVING MaxSeats != count_players;
    ELSE 
        SELECT "Свободных комнат нет" AS Error;
        LEAVE AllRooms;
    END IF;
END;