import Foundation

/// German help topics configuration
struct BerlinTransportMapHelpTopicsConfigurationDE {
    static let allTopics = [
        HelpTopic(
            section: "Erste Schritte",
            title: "Die Kartenansicht verstehen",
            icon: "map.fill",
            content: "Die Karte zeigt Echtzeit-Positionen der Berliner Öffentlichen Verkehrsmittel. Sie können S-Bahn, U-Bahn, Straßenbahnen und Busse mit ihren aktuellen Positionen und Liniennummern sehen.",
            keywords: ["karte", "ansicht", "verkehr", "fahrzeuge"]
        ),
        HelpTopic(
            section: "Erste Schritte",
            title: "Transit-Haltestellen finden",
            icon: "location.fill",
            content: "Transit-Haltestellen sind auf der Karte markiert. Tippen Sie auf einen Haltestellen-Marker, um kommende Abfahrten für diese Station zu sehen. Die Karte lädt automatisch benachbarte Haltestellen, während Sie vergrößern.",
            keywords: ["haltestelle", "station", "finden", "ort"]
        ),
        HelpTopic(
            section: "Live-Tracking",
            title: "Fahrzeuge live verfolgen",
            icon: "tram.fill",
            content: "Farbige Marker zeigen Live-Fahrzeuge auf der Karte. Jede Farbe stellt einen anderen Verkehrstyp dar (rot für S-Bahn, grün für U-Bahn, usw.). Tippen Sie auf ein Fahrzeug, um mehr Details zu sehen, einschließlich seiner Route und des Ziels.",
            keywords: ["fahrzeug", "verfolgung", "live", "position"]
        ),
        HelpTopic(
            section: "Live-Tracking",
            title: "Fahzeugrouten ansehen",
            icon: "arrow.triangle.2.circlepath",
            content: "Wenn Sie auf ein Fahrzeug tippen und seine Details anzeigen, können Sie auf 'Route anzeigen' tippen, um die vollständige Linienstrecke auf der Karte anzuzeigen. Dies hilft Ihnen, den vollständigen Weg des Fahrzeugs durch Berlin zu verstehen.",
            keywords: ["route", "linie", "weg", "richtung"]
        ),
        HelpTopic(
            section: "Abfahrten",
            title: "Abfahrten prüfen",
            icon: "clock.fill",
            content: "Tippen Sie auf eine Haltestelle, um ihre Abfahrten zu sehen. Die Liste zeigt kommende Fahrzeuge mit ihren Liniennummern, Zielen und Abfahrtszeiten. Echtzeit-Aktualisierungen zeigen Ihnen genau, wann Fahrzeuge ankommen.",
            keywords: ["abfahrt", "fahrplan", "zeitplan", "nächste"]
        ),
        HelpTopic(
            section: "Abfahrten",
            title: "Verzögerungsinformationen verstehen",
            icon: "exclamationmark.circle.fill",
            content: "Einige Abfahrten zeigen möglicherweise Verzögerungsinformationen in Echtzeit. Ein roter Indikator bedeutet eine Verzögerung, und die Details zeigen die geschätzte Verzögerung in Minuten.",
            keywords: ["verzögerung", "verspätung", "wartezeit", "benachrichtigung"]
        ),
        HelpTopic(
            section: "Navigation",
            title: "Auf Ihren Standort zentrieren",
            icon: "location.north.fill",
            content: "Die Standort-Schaltfläche in der unteren rechten Ecke ermöglicht es Ihnen, die Karte auf Ihren aktuellen Standort zu zentrieren. Sie müssen der App zuerst Standortberechtigung in den Einstellungen erteilen.",
            keywords: ["standort", "zentrieren", "gps", "position"]
        ),
        HelpTopic(
            section: "Navigation",
            title: "Zoomen und Verschieben",
            icon: "magnifyingglass.circle.fill",
            content: "Verwenden Sie Pinch-to-Zoom zum Zoomen ein und aus. Sie können auch zwei Finger oder Doppeltipp zum Vergrößern verwenden. Wenn Sie näher heranzoomen, erscheinen detailliertere Informationen zu Haltestellen und Fahrzeugen.",
            keywords: ["zoom", "verschieben", "navigieren", "skala"]
        ),
        HelpTopic(
            section: "Funktionen",
            title: "Echtzeit-Aktualisierungen",
            icon: "arrow.clockwise.circle.fill",
            content: "Die Karte wird in Echtzeit aktualisiert, um aktuelle Fahrzeugpositionen anzuzeigen. Aktualisierungen erfolgen automatisch - Sie müssen nicht manuell aktualisieren. Die App wird weiterhin aktualisiert, auch wenn Sie Abfahrten anzeigen.",
            keywords: ["aktualisierung", "echtzeit", "live", "aktualisieren"]
        ),
        HelpTopic(
            section: "Fehlerbehebung",
            title: "Karte wird nicht geladen",
            icon: "exclamationmark.triangle.fill",
            content: "Wenn die Karte nicht lädt:\n1. Überprüfen Sie Ihre Internetverbindung\n2. Stellen Sie sicher, dass Standortberechtigung erteilt ist (für Benutzerstandort)\n3. Versuchen Sie, die App zu schließen und erneut zu öffnen\n4. Überprüfen Sie, ob BVG-Services verfügbar sind",
            keywords: ["fehler", "laden", "karte", "leer"]
        ),
        HelpTopic(
            section: "Fehlerbehebung",
            title: "Keine Fahrzeuge angezeigt",
            icon: "magnifyingglass.fill",
            content: "Wenn Sie keine Fahrzeuge sehen:\n1. Stellen Sie sicher, dass Sie genug vergrößert haben, um Details zu sehen\n2. Überprüfen Sie, dass Sie einen Transit-Bereich mit aktivem Service anzeigen\n3. Einige Fahrzeuge können außerhalb der Stoßzeiten nicht verfügbar sein\n4. Versuchen Sie, die App zu aktualisieren, indem Sie sie erneut öffnen",
            keywords: ["fahrzeuge", "fehlend", "nicht", "anzeigen"]
        ),
        HelpTopic(
            section: "Fehlerbehebung",
            title: "Abfahrten werden nicht aktualisiert",
            icon: "sync.circle.fill",
            content: "Wenn Abfahrten veraltet erscheinen:\n1. Schließen und öffnen Sie das Abfahrts-Blatt erneut\n2. Versuchen Sie, eine andere Haltestelle zu tippen\n3. Überprüfen Sie Ihre Internetverbindung\n4. Die Datenquelle (BVG) könnte Verzögerungen haben",
            keywords: ["abfahrten", "aktualisierung", "veraltet", "alt"]
        ),
        HelpTopic(
            section: "Datenschutz und Daten",
            title: "Datenschutz für Standortdaten",
            icon: "lock.shield.fill",
            content: "Diese App verwendet Ihren Standort nur, wenn Sie explizit die Standort-Schaltfläche tippen. Ihr Standort wird nicht gespeichert oder an einen Server gesendet. Alle Kartendaten kommen von öffentlichen BVG-APIs.",
            keywords: ["datenschutz", "standort", "daten", "sicherheit"]
        )
    ]
}
