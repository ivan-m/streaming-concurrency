{-# LANGUAGE FlexibleContexts, MultiParamTypeClasses #-}

{- |
   Module      : Streaming.Concurrent.Lifted
   Description : Lifted variants of functions in "Streaming.Concurrent"
   Copyright   : Ivan Lazar Miljenovic
   License     : MIT
   Maintainer  : Ivan.Miljenovic@gmail.com

   This module defines variants of those in "Streaming.Concurrent" for
   use with the 'Withable' class, found in the @streaming-with@
   package.

 -}
module Streaming.Concurrent.Lifted
  ( -- * Buffers
    Buffer
  , unbounded
  , bounded
  , latest
  , newest
    -- * Using a buffer
  , withBuffer
  , InBasket(..)
  , OutBasket(..)
    -- * Stream support
  , writeStreamBasket
  , readStreamBasket
  , mergeStreams
  ) where

import           Streaming             (Of, Stream)
import           Streaming.Concurrent  (Buffer, InBasket(..), OutBasket(..),
                                        bounded, latest, newest, unbounded)
import qualified Streaming.Concurrent  as SC
import           Streaming.With.Lifted (Withable(..))

import Control.Monad.Base          (MonadBase)
import Control.Monad.Trans.Control (MonadBaseControl)

--------------------------------------------------------------------------------

-- | Concurrently merge multiple streams together.
--
--   The resulting order is unspecified.
mergeStreams :: (Withable w, MonadBaseControl IO (WithMonad w), MonadBase IO m)
                => Buffer a -> [Stream (Of a) (WithMonad w) v]
                -> w (Stream (Of a) m ())
mergeStreams buff strs = liftWith (SC.mergeStreams buff strs)

-- | Write a single stream to a buffer.
--
--   Type written to make it easier if this is the only stream being
--   written to the buffer.
writeStreamBasket :: (Withable w, MonadBase IO (WithMonad w))
                     => Stream (Of a) (WithMonad w) r -> InBasket a -> w ()
writeStreamBasket stream ib = liftAction (SC.writeStreamBasket stream ib)

-- | Read the output of a buffer into a stream.
--
--   Note that there is no requirement that @m ~ WithMonad w@.
readStreamBasket :: (Withable w, MonadBase IO m) => OutBasket a -> w (Stream (Of a) m ())
readStreamBasket ob = liftWith (SC.readStreamBasket ob)

-- | Use a buffer to asynchronously communicate.
--
--   Two functions are taken as parameters:
--
--   * How to provide input to the buffer (the result of this is
--     discarded)
--
--   * How to take values from the buffer
--
--   As soon as one function indicates that it is complete then the
--   other is terminated.  This is safe: trying to write data to a
--   closed buffer will not achieve anything.
--
--   However, reading a buffer that has not indicated that it is
--   closed (e.g. waiting on an action to complete to be able to
--   provide the next value) but contains no values will block.
withBuffer :: (Withable w, MonadBaseControl IO (WithMonad w))
              => Buffer a -> (InBasket a -> WithMonad w i) -> w (OutBasket a)
withBuffer buffer sendIn = liftWith (SC.withBuffer buffer sendIn)