-- Effect code in the faster rendering path.
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

  case lrSup of --["All", "1", "2", "3", "1:st and 2:nd", "2:nd and 3:rd"]
    "All":
      --lrb = lr
      dmin = 0
      dmax = 29
    "1":
      --lrb = restrict(lr, 0, 9)
      dmin = 0
      dmax = 9
    "2":
      --lrb = restrict(lr, 10, 19)
      dmin = 10
      dmax = 19
    "3":
      --lrb = restrict(lr, 20, 29)
      dmin = 20
      dmax = 29
    "1:st and 2:nd":
      --lrb = restrict(lr, 0, 19)
      dmin = 0
      dmax = 19
    "2:nd and 3:rd":
      --lrb = restrict(lr, 10, 29)
      dmin = 10
      dmax = 29
    otherwise:
      --lrb = lr
      dmin = 0
      dmax = 29
  end case

  case effectr.nm of

    -- Slime
    "Slime", "SlimeX3":
      applyFunc = #applySlimeOnTile

    otherwise:
      return 0

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

      -- Repeats on this tile
      endofloop = mtrxvalue * (0.2 + (0.8 * deepEffect)) * 0.01 * effectr.repeats * fc

      repeat with cntr = 1 to endofloop
        -- Render point
        if deepEffect then
          pnt = (point(q-1, c-1)*20)+point(random(20), random(20))
        else
          if random(2)=1 then
            pnt = (point(q-1, c-1)*20)+point(1 + 19*(random(2)-1), random(20))
          else 
            pnt = (point(q-1, c-1)*20)+point(random(20), 1 + 19*(random(2)-1))
          end if
        end if

        cl = layerlr.getPixel(pnt)
        if (cl = DRWhite) then next repeat
        clA = galr.getPixel(pnt)
        clB = gblr.getPixel(pnt)
        clDc = dclr.getPixel(pnt)
        
        -- Call effect function
        call(applyFunc, me, pnt, dmin, dmax, lr, cl, clA, clB, clDc)
      end repeat

    end repeat
  end repeat

  return 1
end

on applySlimeOnTile me, pnt, dmin, dmax, lr, cl, clA, clB, clDc
  ofst = random(2) - 1
  lgt = 3 + random(random(random(6)))
  if (effectIn3D) then
    -- Re-add this later
    -- nwLr = get3DLr(lr)
  else
    nwLr = restrict(lr - 1 + random(2), dmin, dmax)
  end if

  -- Skip layers that may not be seen
  -- This will alter the behaviour of slime slightly, but it this is a significant speed up
  if (nwLr > 1) then
    strAbLr = string(nwLr-2)
    layerAbLr = member("layer" & strAblr).image
    if (layerAbLr.getPixel(pnt + point(0, lgt)) <> DRWhite) then
      return
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
  
  if (clDc <> DRWhite) then
    dcnwlr = member("layer" & strnwlr & "dc").image
    dcnwlr.copyPixels(DRPxl, slmRect, DRPxlRect, {#color:clDc})
    dcnwlr.copyPixels(DRPxl, slmRect2, DRPxlRect, {#color:clDc})
  end if

  if (gradAf) then
    if (clA <> DRWhite) then
      ganwlr = member("gradientA" & strnwlr).image
      ganwlr.copyPixels(DRPxl, slmRect2, DRPxlRect, {#color:clA})
    end if

    if (clB <> DRWhite) then
      gbnwlr = member("gradientB" & strnwlr).image
      gbnwlr.copyPixels(DRPxl, slmRect2, DRPxlRect, {#color:clB})
    end if
  end if
end