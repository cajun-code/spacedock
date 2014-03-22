package com.funnyhatsoftware.spacedock.holder;

import android.support.v4.util.ArrayMap;
import android.view.View;

import com.funnyhatsoftware.spacedock.fragment.DetailsFragment;

import java.util.List;
import java.util.Set;

/**
 * Class that wraps the static portion of SetItem display - A ItemHolderFactory can be acquired from
 * a SetItem's type, and can be used to create an ListAdapter for displaying SetItems as
 * ItemHolder-managed ListView views.
 */
public abstract class ItemHolderFactory {
    private static final ArrayMap<String, ItemHolderFactory> mFactories =
            new ArrayMap<String, ItemHolderFactory>();

    public static Set<String> getFactoryTypes() {
        return mFactories.keySet();
    }

    public static ItemHolderFactory getHolderFactory(String key) {
        if (!mFactories.containsKey(key)) {
            throw new IllegalStateException("factory of type " + key + " missing");
        }
        return mFactories.get(key);
    }

    private static void registerHolderFactory(ItemHolderFactory factory) {
        String factoryType = factory.getType();
        if (mFactories.containsKey(factoryType)) {
            throw new IllegalArgumentException(
                    "Error: factory with type " + factoryType + " already exists");
        }
        mFactories.put(factory.getType(), factory);
    }

    public static void initialize() {
        if (!mFactories.isEmpty()) throw new IllegalStateException("double init attempted");
        registerHolderFactory(CaptainHolder.getFactory());
        registerHolderFactory(ShipHolder.getFactory());
        registerHolderFactory(FlagshipHolder.getFactory());
        registerHolderFactory(WeaponHolder.getFactory());
        registerHolderFactory(ResourceHolder.getFactory());
        registerHolderFactory(SetHolder.getFactory());
        registerHolderFactory(UpgradeHolder.getFactory(UpgradeHolder.TYPE_STRING_CREW));
        registerHolderFactory(UpgradeHolder.getFactory(UpgradeHolder.TYPE_STRING_TALENT));
        registerHolderFactory(UpgradeHolder.getFactory(UpgradeHolder.TYPE_STRING_TECH));
    }

    private final String mType;

    public ItemHolderFactory(String type) {
        mType = type;
    }

    public String getType() { return mType; }
    public boolean usesFactions() { return true; }
    public abstract ItemHolder createHolder(View view);
    public abstract List<?> getItemsForFaction(String faction);
    public abstract String getDetails(DetailsFragment.DetailDataBuilder builder, String id);
}
