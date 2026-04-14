import { createReducer, on, createAction, props } from '@ngrx/store';

export interface ConfigState {
  toggleSidebar: boolean;
  headerTheme: string;
  sidebarTheme: string;
}

const initialState: ConfigState = {
  toggleSidebar: false,
  headerTheme: 'header-default',
  sidebarTheme: 'sidebar-default',
};

export const toggleSidebar = createAction('[Config] Toggle Sidebar');
export const setHeaderTheme = createAction('[Config] Set Header Theme', props<{ theme: string }>());

export const configReducer = createReducer(
  initialState,
  on(toggleSidebar, (state) => ({ ...state, toggleSidebar: !state.toggleSidebar })),
  on(setHeaderTheme, (state, { theme }) => ({ ...state, headerTheme: theme })),
);
