import React from "react";
import { Link } from "react-router-dom";
import { proxyImage } from "../image";

const fallback = "/images/profile.jpg"
export default function ProfilePicture(props){

  let onError = (e) => {
    e.target.src=fallback
  }
  let src = props.src ? proxyImage(props.src, 48, 48, "fill") : fallback
  let pfp = <div className={"pfp " + props.type} onClick={props.onClick}>
              <img src={src} onError={onError}></img>
              <div className="filter ts"></div>
            </div>
  if(!props.onClick && !props.noLink){
    pfp = <Link to={props.to} onClick={(e) => e.stopPropagation()}>
      {pfp}
    </Link>
  }
  return pfp
}