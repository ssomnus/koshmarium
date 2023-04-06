DROP PROCEDURE IF EXISTS Mourner;
CREATE PROCEDURE Mourner(PlayerID INT)
COMMENT "Способность Плакальщик (ID игрока)"
ActivationAbility: BEGIN
    /*Добавить карты в таблицу PlayerDeck*/
    INSERT INTO PlayerDeck(ID_Card, ID_Player, CardIsDiscarded) SELECT ID_CardInGame, PlayerID, "NO" FROM CommonDeck 
                        LIMIT 2;

    /*Удаление новых карт из таблицы CommonDeck*/
    DELETE CommonDeck FROM CommonDeck
        JOIN PlayerDeck ON CommonDeck.ID_CardInGame = PlayerDeck.ID_Card
        WHERE ID_CardInGame = ID_Card;
END;