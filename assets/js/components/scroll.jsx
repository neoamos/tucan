
import React, { useRef, useEffect } from "react";
import { useLocation } from "react-router-dom";

export function ScrollToTopOnMount() {
  useEffect(() => {
    window.scrollTo(0, 0);
  }, []);

  return null;
}


export function ScrollToTop() {
  const { pathname } = useLocation();

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);

  return null;
}

export function ScrollHere() {
  const ref = useRef(null);
  const location = useLocation();

  useEffect(() => {
    window.scrollTo(0, ref.current.offsetTop - 53)
  }, [location]);

  return (
    <span ref={ref}></span>
  );
}

export function InfiniteScroll(props){

  useEffect(() => {
    console.log("a")
    window.onscroll = function(e){
      let scroll = document.documentElement.scrollHeight - (document.documentElement.scrollTop +  document.documentElement.clientHeight) <  2 * document.documentElement.clientHeight
      if(scroll && !props.fetching && !props.ended){
        props.fetch()
      }
    }
  }, [])
  return <></>
}