-- Faster effects for the Render Optimisations option. Mostly written by Of Incandescence.
-- A lot of the code written here is static-typed, hoping that makes at least some miniscule performance difference in Drizzle lol

-- NOTE: If you going to write a custom effect, do not implement it here,
-- and ensure it is accessible by the old path (west, past the farm arrays) so it will work with Render Optimisations disabled.
-- Ideally, although optional, a custom effect would be compatible to be hooked in the fast path,
-- i.e. your effect code is contained in a function with the same parameters as the `apply<effect>OnTile` functions and similar here.
-- Explore the parent functions (the ones that call `call`) to see how to hook your effect into the fast path directly.

global vertRepeater, r, gEEprops, solidMtrx, gLEprops, colr, colrDetail, colrInd, gdLayer, gdDetailLayer, gdIndLayer, gLOProps, gLevel, gEffectProps, gRenderCameraTilePos, effectSeed, lrSup, chOp, fatOp, gradAf, effectIn3D, gAnyDecals, gRotOp, slimeFxt, DRDarkSlimeFix, DRWhite, DRPxl, DRPxlRect, effSide, gCustomEffects, gEffects, gLastImported, skyRootsFix, lampColr, lampLayer

-- It's going to take awhile before everything is ported over, if they ever are...
-- So if a given effect is not ported, false is returned, and the vanilla path should run instead.
on fastEffectProcess(fromq: number, toq: number, row: number, effectr)
  case effectr.tp of
     -- Currently only some erosion types are ported
    "standardErosion":
      return applyFastStandardErosion(fromq, toq, row, effectr)

    otherwise:
      -- Everything else just render using the usual code, lol
      return 0

  end case
end

on applyFastStandardErosion(me, fromq: number, toq: number, row: number, effectr)
  affop: number = effectr.affectOpenAreas
  c: number = row - gRenderCameraTilePos.locV
  applyFunc = VOID

  -- Map effects to applyFunc
  case effectr.nm of
    -- Slime
    "Slime", "SlimeX3":
      applyFunc = #applySlimeOnTile

    -- Rust
    "Rust":
      applyFunc = #applyRustOnTile

    -- Barnacles
    "Barnacles":
      applyFunc = #applyBarnaclesOnTile
    
    -- Roughen
    "Roughen":
      applyFunc = #applyRoughenOnTile

    otherwise:
      -- Skip and do regular effect rendering path
      return 0
  end case

  dmin: number = 0
  dmax: number = 29
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
  end case

  repeat with q2 = fromq to toq
    q: number = q2 - gRenderCameraTilePos.locH    

    -- Flipping the order of the loops here causes different results. This is closer to vanilla
    repeat with d = 30 - dmax to 30 - dmin
      lr: number = 30-d
      strlr: string = string(lr)
      layerlr: image = member("layer" & strlr).image
      galr: image = member("gradientA" & strlr).image
      gblr: image = member("gradientB" & strlr).image
      dclr: image = member("layer" & strlr & "dc").image  

      if (lr = 9) or (lr = 19) or (lr = 29) then
        lraddc: number = 1 + (d > 9) + (d > 19)
        sld: number = (solidMtrx[q2][row][lraddc])
        fc: number = affop + (1.0-affop) * (solidAfaMv(point(q2, row), lraddc))
      end if

      deepEffect: number = 0
      if (lr = 0) or (lr = 10) or (lr = 20) or (sld = 0) then
        deepEffect = 1
      end if

      mtrxvalue: number = effectr.mtrx[q2][row]
      endofloop: number = mtrxvalue * (0.2 + (0.8 * deepEffect)) * 0.01 * effectr.repeats * fc

      repeat with cntr = 1 to endofloop
        -- Decide point
        pnt: point = point(q-1, c-1) * 20
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

-- Slime & SlimeX3
on applySlimeOnTile(pnt: point, dmin: number, dmax: number, lr: number, layerlr: image, galr: image, gblr: image, dclr: image)
  cl: color = layerlr.getPixel(pnt)
  if (cl = DRWhite) then return

  ofst: number = random(2) - 1
  lgt: number = 3 + random(random(random(6)))
  if (effectIn3D) then
    nwLr: number = get3DLr(lr)
  else
    nwLr: number = restrict(lr - 1 + random(2), dmin, dmax)
  end if

  -- Skip layers that may not be seen
  -- This will alter the behaviour of slime slightly, but it this is a significant speed up
  if (nwLr > 1) then
    strAbLr: string = string(nwLr-2)
    layerAbLr: image = member("layer" & strAblr).image
    pnt2: point = pnt + point(ofst, lgt)
    if (layerAbLr.getPixel(pnt2) <> DRWhite) then
      -- Preserve slimy walls and such. Potentially increase the range of this in the future?
      -- A difference will most likely only be seen on significant camera angles.
      if (layerAbLr.getPixel(pnt2 + point(5, 0)) <> DRWhite) and (layerAbLr.getPixel(pnt2 - point(5, 0)) <> DRWhite) then
        return
      end if
    end if
  end if

  strnwlr: string = string(nwLr)
  layernwlr: image = member("layer" & strnwlr).image
  
  slmRect: rect = rect(pnt, pnt) + rect(0 + ofst, 0, 1 + ofst, lgt)
  if (random(2) = 1) then
    slmRect2: rect = slmRect + rect(1, 1, 1, -1)
  else
    slmRect2: rect = slmRect + rect(-1, 1, -1, -1)
  end if

  layernwlr.copyPixels(DRPxl, slmRect, DRPxlRect, {#color:cl})
  layernwlr.copyPixels(DRPxl, slmRect2, DRPxlRect, {#color:cl})
  
  clDc: color = dclr.getPixel(pnt)
  if (clDc <> DRWhite) then
    dcnwlr: image = member("layer" & strnwlr & "dc").image
    dcnwlr.copyPixels(DRPxl, slmRect, DRPxlRect, {#color:clDc})
    dcnwlr.copyPixels(DRPxl, slmRect2, DRPxlRect, {#color:clDc})
  end if

  if (gradAf) then
    clA: color = galr.getPixel(pnt)
    clB: color = gblr.getPixel(pnt)

    if (clA <> DRWhite) then
      ganwlr: image = member("gradientA" & strnwlr).image
      ganwlr.copyPixels(DRPxl, slmRect, DRPxlRect, {#color:clA})
      ganwlr.copyPixels(DRPxl, slmRect2, DRPxlRect, {#color:clA})
    end if

    if (clB <> DRWhite) then
      gbnwlr: image = member("gradientB" & strnwlr).image
      gbnwlr.copyPixels(DRPxl, slmRect, DRPxlRect, {#color:clA})
      gbnwlr.copyPixels(DRPxl, slmRect2, DRPxlRect, {#color:clB})
    end if
  end if
end

-- Rust
on applyRustOnTile(pnt: point, dmin: number, dmax: number, lr: number, layerlr: image, galr: image, gblr: image, dclr: image)
  pnt = pnt + degToVec(random(360))*4
  cl: color = layerlr.getPixel(pnt)
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

  rustdot: image = member("rustDot").image
  pnt2: point = pnt + point(random(2)-1, 0)
  destRect: rect = rect(pnt2, pnt2) + rect(-2, -2, 2, 2)

  layernwlr.copyPixels(rustdot, destRect, rustdot.rect, {#color:cl, #ink:36})
  if (gradAf) then
    clDc: color = dclr.getPixel(pnt)
    clA: color = galr.getPixel(pnt)
    clB: color = gblr.getPixel(pnt)
    if (clDc <> DRWhite) then
      member("layer"&strnwlr&"dc").image.copyPixels(rustdot, destRect, rustdot.rect, {#color:clDc, #ink:36})
    end if
    if (clA <> DRWhite) then
      member("gradientA"&strnwlr).image.copyPixels(rustdot, destRect, rustdot.rect, {#color:clA, #ink:36})
    end if
    if (clB <> DRWhite) then
      member("gradientB"&strnwlr).image.copyPixels(rustdot, destRect, rustdot.rect, {#color:clB, #ink:36})
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

-- Barnacles
on applyBarnaclesOnTile(pnt: point, dmin: number, dmax: number, lr: number, layerlr: image, galr: image, gblr: image, dclr: image)
  pnt = pnt + degToVec(random(360))*4
  cl: color = layerlr.getPixel(pnt)
  if (cl = DRWhite) then return

  if (effectIn3D) then
    nwLr: number = get3DLr(lr)
  else
    nwLr: number = restrict(lr - 1 + random(2), dmin, dmax)
  end if

  strnwlr: string = string(nwLr)
  layernwlr: image = member("layer" & strnwlr).image

  if random(2)-1 then

    b1: image = member("barnacle1").image
    b2: image = member("barnacle2").image

    destRect: rect = rect(pnt, pnt)+rect(-3,-3,4,4)
    layernwlr.copyPixels(b1, destRect, b1.rect, {#color:cl, #ink:36})
    layernwlr.copyPixels(b2, destRect+rect(1,1,-1,-1), b2.rect, {#color:color(255,0,0), #ink:36})

    if (gradAf) then
      clDc: color = dclr.getPixel(pnt)
      clA: color = galr.getPixel(pnt)
      clB: color = gblr.getPixel(pnt)
      if (clDc <> DRWhite)then
        member("layer"&strnwlr&"dc").image.copyPixels(b1, destRect, b1.rect, {#color:clDc, #ink:36})
      end if
      if (clA <> DRWhite)then
        member("gradientA"&strnwlr).image.copyPixels(b1, destRect, b1.rect, {#color:clA, #ink:36})
      end if
      if (clB <> DRWhite)then
        member("gradientB"&strnwlr).image.copyPixels(b1, destRect, b1.rect, {#color:clB, #ink:36})
      end if
    end if

  else

    rustdot: image = member("rustDot").image
    ofst: number = random(2)-1
    destRect: rect = rect(pnt, pnt) + rect(-2+ofst, -2, 2+ofst, 2)
    layernwlr.copyPixels(rustdot, destRect, rustdot.rect, {#color:[color(255,0,0),cl][random(2)], #ink:36})

    if (gradAf) then
      clDc: color = dclr.getPixel(pnt)
      clA: color = galr.getPixel(pnt)
      clB: color = gblr.getPixel(pnt)
      if (clDc <> DRWhite)then
        member("layer"&strnwlr&"dc").image.copyPixels(rustdot, destRect, rustdot.rect, {#color:clDc, #ink:36})
      end if
      if (clA <> DRWhite)then
        member("gradientA"&strnwlr).image.copyPixels(rustdot, destRect, rustdot.rect, {#color:clA, #ink:36})
      end if
      if (clB <> DRWhite)then
        member("gradientB"&strnwlr).image.copyPixels(rustdot, destRect, rustdot.rect, {#color:clB, #ink:36})
      end if
    end if

  end if
end if


-- Roughen
on applyRoughenOnTile(pnt: point, dmin: number, dmax: number, lr: number, layerlr: image, galr: image, gblr: image, dclr: image)
  cl: color = layerlr.getPixel(pnt)
  if (cl = color(0, 255, 0)) then
    roughenImg: image = member("roughenTexture").image
    var: number = random(20)
    repeat with lch = 0 to 6
      repeat with lcv = 0 to 6
        if(layerlr.getPixel(pnt.locH-3+lch, pnt.locV-3+lcv) = color(0, 255, 0))then
          gtCl: color = roughenImg.getPixel(lch+(var-1)*7, lcv)
          if gtCl <> DRWhite then
            layerlr.setPixel(pnt.locH-3+lch, pnt.locV-3+lcv, gtCl)
          end if
        end if
      end repeat
    end repeat
  end if
end