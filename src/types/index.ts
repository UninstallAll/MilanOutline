// src/types/index.ts
export interface OutlineNode {
  id: string;
  title: string;
  content?: string;
  parentId?: string;
  children: OutlineNode[];
  level: number;
  sortOrder: number;
  isExpanded: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface Outline {
  id: string;
  title: string;
  description?: string;
  nodes: OutlineNode[];
  createdAt: Date;
  updatedAt: Date;
}

export interface AppState {
  outlines: Outline[];
  currentOutlineId: string | null;
  selectedNodeId: string | null;
  isLoading: boolean;
  searchQuery: string;
}

export interface StorageData {
  outlines: Outline[];
  settings: AppSettings;
}

export interface AppSettings {
  theme: 'light' | 'dark';
  sidebarWidth: number;
  autoSave: boolean;
  shortcuts: Record<string, string>;
}

export type MessageType = 
  | 'TOGGLE_SIDEBAR'
  | 'ADD_NODE'
  | 'UPDATE_NODE'
  | 'DELETE_NODE'
  | 'FOCUS_SEARCH';

export interface Message {
  type: MessageType;
  payload?: any;
}
