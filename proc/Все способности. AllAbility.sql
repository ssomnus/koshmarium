DROP PROCEDURE IF EXISTS ActivationAbility;
CREATE PROCEDURE ActivationAbility()
COMMENT "Активация способностей (токен, ID игрока, ID карты, ID монстра)"
ActivationAbility: BEGIN
    DECLARE abl VARCHAR(20) DEFAULT(SELECT Ability FROM Cards
                                        JOIN CardsInGame ON Cards.ID = CardsInGame.ID_Card
                                        JOIN UsedParts ON CardsInGame.ID = UsedParts.ID_Card
                                        JOIN MonsterCards ON CardsInGame.ID = MonsterCards.ID_Card
                                        JOIN Monsters ON MonsterCards.ID_Monster = Monsters.ID
                                        WHERE NameBodyPart = "Ноги" AND ID_Player = PlayerID AND ID_Monster = MonsterID);

    CASE abl
        WHEN "Певчий" THEN
        BEGIN
            /*Добавить карты в таблицу ChoristerDeck*/
            INSERT INTO ChoristerDeck(ID_Card) SELECT ID_CardInGame FROM CommonDeck
                LIMIT 2;

            /*Удаление новых карт из таблицы CommonDeck*/
            DELETE CommonDeck FROM CommonDeck
                JOIN ChoristerDeck ON CommonDeck.ID_CardInGame = ChoristerDeck.ID_Card
                WHERE ID_CardInGame = ChoristerDeck.ID_Card;

            /*Активация способности Певчий*/
            SELECT "Активируйте способность Певчий. Выложите две карты из временной колоды (без ограничений по легиону). Те карты, которые выложить не получится, будут отправлены в сброс" AS System;
            
            LEAVE ActivationAbility;
        END;

        WHEN "Плакальщик" THEN
        BEGIN
            /*Добавить карты в таблицу PlayerDeck*/
            INSERT INTO PlayerDeck(ID_Card, ID_Player, CardIsDiscarded) SELECT ID_CardInGame, PlayerID, "NO" FROM CommonDeck 
                LIMIT 2;

            /*Удаление новых карт из таблицы CommonDeck*/
            DELETE CommonDeck FROM CommonDeck
                JOIN PlayerDeck ON CommonDeck.ID_CardInGame = PlayerDeck.ID_Card
                -- JOIN Players ON PlayerDeck.ID_Player = ID
                -- JOIN Tokens ON Players.Login = Tokens.login
                WHERE ID_CardInGame = ID_Card;

            /*Активация способности Плакальщик*/
            SELECT "Способность Плакальщик была активирована. Новые карты добавлены в вашу колоду" AS System;

            LEAVE ActivationAbility;
        END;

        WHEN "Пересмешник" THEN
        BEGIN
            /*Активация способности Пересмешник*/
            SELECT "Активируйте способность Пересмешник. Выложите одну карту из своей колоды (без ограничений по легиону)" AS System;

            LEAVE ActivationAbility;
        END;

        WHEN "Палач" THEN
        BEGIN
            /*Активация способности Палач*/
            SELECT "Активируйте способность Палач. Заберите на руку верхнюю карту любого чужого Монстра" AS System;

            LEAVE ActivationAbility;
        END;

        WHEN "Падальщик" THEN
        BEGIN
            /*Активация способности Падальщик*/
            SELECT "Активируйте способность Падальщик. Сбросьте любого чужого незавершенного Монстра" AS System;

            LEAVE ActivationAbility;
        END;

        WHEN "Пожиратель" THEN
        BEGIN
            /*Активация способности Пожиратель*/
            SELECT "Активируйте способность Пожиратель. Сбросьте верхнюю карту любого своего Монстра, кроме этого" AS System;

            LEAVE ActivationAbility;
        END;

        WHEN NULL THEN
        BEGIN
            /*Способности нет*/
            UPDATE MonsterCards SET AbilityIsBeingUsed = "YES"
                JOIN CardsInGame ON MonsterCards.ID_CardInGame = CardsInGame.ID
                JOIN Cards ON CardsInGame.ID_Card = Cards.ID
                WHERE Ability IS NULL AND ID_Monster = MonsterID;

            LEAVE ActivationAbility;
        END;
    END CASE;
END;