import React from "react";

import { MainHeader } from "../layout";
import { ScrollToTop } from "../components/scroll"
import { useTitle } from "../components/ui_elements"

import PostForm from "../components/post_form"

export default function About(){
  useTitle("New Post", [])
  return (
    <div style={{height: "100%"}}>
      <ScrollToTop />
      <MainHeader>
        <h2>New Post</h2>
      </MainHeader>
      <PostForm />
    </div>
  )
}