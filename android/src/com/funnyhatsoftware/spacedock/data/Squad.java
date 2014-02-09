
package com.funnyhatsoftware.spacedock.data;

import java.io.InputStream;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

public class Squad extends SquadBase {

    static String convertStreamToString(InputStream is) {
        java.util.Scanner s = new java.util.Scanner(is);
        s.useDelimiter("\\A");
        String value = s.hasNext() ? s.next() : "";
        s.close();
        return value;
    }

    public EquippedShip getSideboard() {
        EquippedShip sideboard = null;

        for (EquippedShip target : mEquippedShips) {
            if (target.getIsResourceSideboard()) {
                sideboard = target;
                break;
            }
        }
        return sideboard;
    }

    public EquippedShip addSideboard() {
        EquippedShip sideboard = getSideboard();
        if (sideboard == null) {
            sideboard = new Sideboard();
            mEquippedShips.add(sideboard);
        }
        return sideboard;
    }

    EquippedShip removeSideboard() {
        EquippedShip sideboard = getSideboard();

        if (sideboard != null) {
            mEquippedShips.remove(sideboard);
        }

        return sideboard;
    }

    public void importFromStream(Universe universe, InputStream is)
            throws JSONException {
        JSONTokener tokenizer = new JSONTokener(convertStreamToString(is));
        JSONObject jsonObject = new JSONObject(tokenizer);
        setNotes(jsonObject.getString("notes"));
        setName(jsonObject.getString("name"));
        setAdditionalPoints(jsonObject.optInt("additionalPoints"));
        String resourceId = jsonObject.optString("resource");
        if (resourceId != null) {
            Resource resource = universe.resources.get(resourceId);
            setResource(resource);
        }

        JSONArray ships = jsonObject.getJSONArray("ships");
        EquippedShip currentShip = null;
        for (int i = 0; i < ships.length(); ++i) {
            JSONObject shipData = ships.getJSONObject(i);
            boolean shipIsSideboard = shipData.optBoolean("sideboard");
            if (shipIsSideboard) {
                currentShip = getSideboard();
            } else {
                String shipId = shipData.optString("shipId");
                Ship targetShip = universe.getShip(shipId);
                currentShip = new EquippedShip(targetShip);
            }
            currentShip.importUpgrades(universe, shipData);
            add(currentShip);
        }
    }

    public void add(EquippedShip ship) {
        mEquippedShips.add(ship);
        ship.setSquad(this);
    }

    public int calculateCost() {
        int cost = 0;

        Resource resource = getResource();
        if (resource != null) {
            cost += resource.getCost();
        }

        cost += getAdditionalPoints();

        for (EquippedShip ship : mEquippedShips) {
            cost += ship.calculateCost();
        }

        return cost;
    }
}
