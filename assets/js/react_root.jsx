import React from "react";
import {createRoot} from 'react-dom/client';
import {
  createBrowserRouter,
  RouterProvider,
} from "react-router-dom";

import store from './store'
import { Provider } from 'react-redux'

import { Layout } from "./layout"
import Timeline from "./pages/timeline"
import Profile from "./pages/profile"
import About from "./pages/about"
import Login from "./pages/login"
import Post from "./pages/post"
import Following from "./pages/following"
import Settings from "./pages/settings"
import Notifications from "./pages/notifications";
import Messages from "./pages/messages";
import NewPost from "./pages/new_post"
import Search from "./pages/search"

const router = createBrowserRouter([
  {
    path: "/",
    element: <Layout />,
    children: [
      {
        path: "/",
        element: <Timeline />
      },
      {
        path: "/about",
        element: <About />
      },
      {
        path: "/login",
        element: <Login />
      },
      {
        path: "/settings",
        element: <Settings />
      },
      {
        path: "/notifications",
        element: <Notifications />
      },
      {
        path: "/messages",
        element: <Messages />
      },
      {
        path: "/post/:post_id",
        element: <Post />
      },
      {
        path: "/profile/:pubkey",
        element: <Profile />
      },
      {
        path: "/profile/:pubkey/:following",
        element: <Following />
      },
      {
        path: "/new-post",
        element: <NewPost />
      },
      {
        path: "/search",
        element: <Search />
      }
    ]
  },
]);

const root = createRoot(document.getElementById("root"));
root.render(
  // <React.StrictMode>
  <Provider store={store}>
    <RouterProvider router={router} />
  </Provider>
  // </React.StrictMode>
);