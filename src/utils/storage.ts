// src/utils/storage.ts
import { StorageData, Outline, AppSettings } from '../types';

export class StorageManager {
  private static instance: StorageManager;
  
  static getInstance(): StorageManager {
    if (!StorageManager.instance) {
      StorageManager.instance = new StorageManager();
    }
    return StorageManager.instance;
  }
  
  async saveOutlines(outlines: Outline[]): Promise<void> {
    await chrome.storage.local.set({ outlines });
  }
  
  async loadOutlines(): Promise<Outline[]> {
    const result = await chrome.storage.local.get(['outlines']);
    return result.outlines || [];
  }
  
  async saveSettings(settings: AppSettings): Promise<void> {
    await chrome.storage.local.set({ settings });
  }
  
  async loadSettings(): Promise<AppSettings> {
    const result = await chrome.storage.local.get(['settings']);
    return result.settings || this.getDefaultSettings();
  }
  
  async exportData(): Promise<string> {
    const data = await chrome.storage.local.get();
    return JSON.stringify(data, null, 2);
  }
  
  async importData(jsonData: string): Promise<void> {
    try {
      const data = JSON.parse(jsonData);
      await chrome.storage.local.set(data);
    } catch (error) {
      throw new Error('Invalid JSON data');
    }
  }
  
  async clearAll(): Promise<void> {
    await chrome.storage.local.clear();
  }
  
  private getDefaultSettings(): AppSettings {
    return {
      theme: 'light',
      sidebarWidth: 400,
      autoSave: true,
      shortcuts: {
        'toggle-outline': 'Ctrl+Shift+O',
        'add-node': 'Ctrl+Shift+N',
        'focus-search': 'Ctrl+Shift+F'
      }
    };
  }
}
