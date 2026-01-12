-- Faster effects for the Render Optimisations option. Mostly written by Of Incandescence
global vertRepeater, r, gEEprops, solidMtrx, gLEprops, colr, colrDetail, colrInd, gdLayer, gdDetailLayer, gdIndLayer, gLOProps, gLevel, gEffectProps, gRenderCameraTilePos, effectSeed, lrSup, chOp, fatOp, gradAf, effectIn3D, gAnyDecals, gRotOp, slimeFxt, DRDarkSlimeFix, DRWhite, DRPxl, DRPxlRect, effSide, gCustomEffects, gEffects, gLastImported, skyRootsFix, lampColr, lampLayer

-- It's going to take awhile before everything is ported over, if they ever are...
-- So if a given effect is not ported, false is returned, and the vanilla path should run instead.
on fastEffectProcess me, fromq, toq, row, effectr
  case effectr.tp of
     -- Currently only some erosion types are ported
    "standardErosion":
      return applyFastStandardErosion(fromq, toq, row, effectr)

    otherwise:
      -- Everything else just render using the usual code, lol
      return 0

  end case
end

on applyFastStandardErosion me, fromq, toq, row, effectr
  affop = effectr.affectOpenAreas
  c = row - gRenderCameraTilePos.locV
  applyFunc = VOID

  -- Map effects to applyFunc
  case effectr.nm of
    -- Slime
    "Slime", "SlimeX3":
      applyFunc = #applySlimeOnTile

    -- Rust
    "Rust":
      applyFunc = #applyRustOnTile

    otherwise:
      -- Skip and do regular effect rendering path
      return 0
  end case

  case lrSup of --["All", "1", "2", "3", "1:st and 2:nd", "2:nd and 3:rd"]
    "All":
      dmin = 0
      dmax = 29
    "1":
      dmin = 0
      dmax = 9
    "2":
      dmin = 10
      dmax = 19
    "3":
      dmin = 20
      dmax = 29
    "1:st and 2:nd":
      dmin = 0
      dmax = 19
    "2:nd and 3:rd":
      dmin = 10
      dmax = 29
    otherwise:
      dmin = 0
      dmax = 29
  end case

  repeat with q2 = fromq to toq
    q = q2 - gRenderCameraTilePos.locH    

    -- Flipping the order of the loops here causes different results. This is closer to vanilla
    repeat with d = 30 - dmax to 30 - dmin
      lr = 30-d
      strlr = string(lr)
      layerlr = member("layer" & strlr).image
      galr = member("gradientA" & strlr).image
      gblr = member("gradientB" & strlr).image
      dclr = member("layer" & strlr & "dc").image  

      if (lr = 9) or (lr = 19) or (lr = 29) then
        lraddc = 1 + (d > 9) + (d > 19)
        sld = (solidMtrx[q2][row][lraddc])
        fc = affop + (1.0-affop) * (solidAfaMv(point(q2, row), lraddc))
      end if

      deepEffect = 0
      if (lr = 0) or (lr = 10) or (lr = 20) or (sld = 0) then
        deepEffect = 1
      end if

      mtrxvalue = effectr.mtrx[q2][row]
      endofloop = mtrxvalue * (0.2 + (0.8 * deepEffect)) * 0.01 * effectr.repeats * fc

      repeat with cntr = 1 to endofloop
        -- Decide point
        pnt = point(q-1, c-1) * 20
        if deepEffect then
          pnt = pnt + point(random(20), random(20))
        else
          if random(2)=1 then
            pnt = pnt + point(1 + 19 * (random(2)-1), random(20))
          else 
            pnt = pnt + point(random(20), 1 + 19 * (random(2)-1))
          end if
        end if
        
        -- Call effect function
        -- Of Incandescence: call was not implemented in Drizzle, and we had to implement it ourself. Keep that in-mind when merging this into Drizzle, lol
        -- We also developed and tested on Drizzle, so if this does not work in Director...uh oh
        call(applyFunc, me, pnt, dmin, dmax, lr, layerlr, galr, gblr, dclr)
      end repeat

    end repeat
  end repeat

  return 1
end

on applySlimeOnTile me, pnt, dmin, dmax, lr, layerlr, galr, gblr, dclr
  cl = layerlr.getPixel(pnt)
  if (cl = DRWhite) then return

  ofst = random(2) - 1
  lgt = 3 + random(random(random(6)))
  if (effectIn3D) then
    nwLr = get3DLr(lr)
  else
    nwLr = restrict(lr - 1 + random(2), dmin, dmax)
  end if

  -- Skip layers that may not be seen
  -- This will alter the behaviour of slime slightly, but it this is a significant speed up
  if (nwLr > 1) then
    strAbLr = string(nwLr-2)
    layerAbLr = member("layer" & strAblr).image
    pnt2 = pnt + point(ofst, lgt)
    if (layerAbLr.getPixel(pnt2) <> DRWhite) then
      -- Preserve slimy walls and such. Potentially increase the range of this in the future?
      -- A difference will most likely only be seen on significant camera angles.
      if (layerAbLr.getPixel(pnt2 + point(5, 0)) <> DRWhite) and (layerAbLr.getPixel(pnt2 - point(5, 0)) <> DRWhite) then
        return
      end if
    end if
  end if

  strnwlr = string(nwLr)
  layernwlr = member("layer" & strnwlr).image
  
  slmRect = rect(pnt, pnt) + rect(0 + ofst, 0, 1 + ofst, lgt)
  if (random(2) = 1) then
    slmRect2 = slmRect + rect(1, 1, 1, -1)
  else
    slmRect2 = slmRect + rect(-1, 1, -1, -1)
  end if

  layernwlr.copyPixels(DRPxl, slmRect, DRPxlRect, {#color:cl})
  layernwlr.copyPixels(DRPxl, slmRect2, DRPxlRect, {#color:cl})
  
  clDc = dclr.getPixel(pnt)
  if (clDc <> DRWhite) then
    dcnwlr = member("layer" & strnwlr & "dc").image
    dcnwlr.copyPixels(DRPxl, slmRect, DRPxlRect, {#color:clDc})
    dcnwlr.copyPixels(DRPxl, slmRect2, DRPxlRect, {#color:clDc})
  end if

  if (gradAf) then
    clA = galr.getPixel(pnt)
    clB = gblr.getPixel(pnt)

    if (clA <> DRWhite) then
      ganwlr = member("gradientA" & strnwlr).image
      ganwlr.copyPixels(DRPxl, slmRect, DRPxlRect, {#color:clA})
      ganwlr.copyPixels(DRPxl, slmRect2, DRPxlRect, {#color:clA})
    end if

    if (clB <> DRWhite) then
      gbnwlr = member("gradientB" & strnwlr).image
      gbnwlr.copyPixels(DRPxl, slmRect, DRPxlRect, {#color:clA})
      gbnwlr.copyPixels(DRPxl, slmRect2, DRPxlRect, {#color:clB})
    end if
  end if
end

on applyRustOnTile me, pnt, dmin, dmax, lr, layerlr, galr, gblr, dclr
  pnt = pnt + degToVec(random(360))*4
  cl = layerlr.getPixel(pnt)
  if (cl = DRWhite) then return

  if (effectIn3D) then
    nwLr = get3DLr(lr)
    strnwlr = string(nwLr)
    layernwlr = member("layer"&strnwlr).image
  else
    nwLr = lr
    strnwlr = string(lr)
    layernwlr = layerlr
  end if

  -- No skip layer trick here, there does not seem to be a significant speed-up unlike in slime's case
  -- or at least on Drizzle, reminder we (Of Incandescence) are trapped in the land of Drizzle's codebase :despair:

  pnt2 = pnt + point(random(2)-1, 0)
  rustdot = member("rustDot").image
  layernwlr.copyPixels(rustdot, rect(pnt2, pnt2) + rect(-2, -2, 2, 2), rustdot.rect, {#color:cl, #ink:36})
  if (gradAf) then
    clDc = dclr.getPixel(pnt)
    clA = galr.getPixel(pnt)
    clB = gblr.getPixel(pnt)
    if (clDc <> DRWhite) then
      member("layer"&strnwlr&"dc").image.copyPixels(rustdot, rect(pnt2, pnt2)+rect(-2,-2,2,2), rustdot.rect, {#color:clDc, #ink:36})
    end if
    if (clA <> DRWhite) then
      member("gradientA"&strnwlr).image.copyPixels(rustdot, rect(pnt2, pnt2)+rect(-2,-2,2,2), rustdot.rect, {#color:clA, #ink:36})--comment below
    end if
    if (clB <> DRWhite) then
      member("gradientB"&strnwlr).image.copyPixels(rustdot, rect(pnt2, pnt2)+rect(-2,-2,2,2), rustdot.rect, {#color:clB, #ink:36})--not using 39-darker here because 36 makes things look better
    end if
  end if

end

on get3DLr me, lr, dmin, dmax
  nwLr = restrict(lr - 2 + random(3), dmin, dmax)
  if (lr = 6) and (nwLr = 5) then
    nwLr = 6
  else if (lr = 5) and (nwLr = 6) then
    nwLr = 5
  end if
  return nwLr
end 
