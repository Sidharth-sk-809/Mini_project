import { createContext, useContext, useMemo, useState } from 'react';

const ShopContext = createContext(null);
const STORAGE_KEY = 'admin_selected_shop_code';

export function ShopProvider({ children }) {
  const [selectedShopCode, setSelectedShopCode] = useState(() => {
    try {
      return localStorage.getItem(STORAGE_KEY) ?? '';
    } catch {
      return '';
    }
  });

  const setShop = (code) => {
    setSelectedShopCode(code || '');
    try {
      if (code) {
        localStorage.setItem(STORAGE_KEY, code);
      } else {
        localStorage.removeItem(STORAGE_KEY);
      }
    } catch {
      // no-op
    }
  };

  const value = useMemo(() => ({ selectedShopCode, setShop }), [selectedShopCode]);

  return <ShopContext.Provider value={value}>{children}</ShopContext.Provider>;
}

export const useShop = () => useContext(ShopContext);
